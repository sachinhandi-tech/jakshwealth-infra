"""Async NSE daily-candle scan. Reads Kite. Never places or changes orders."""

from __future__ import annotations

import json
import threading
import time
import uuid
from datetime import datetime, timedelta, timezone
from pathlib import Path

HISTORY_DAYS = 120
REQUEST_GAP_SECONDS = 0.35
DATA_DIR = Path("/var/lib/nse-scan")
CREDENTIAL_PATH = Path("/etc/jakshwealth-parallel/kite.env")

_LOCK = threading.Lock()
_THREAD: threading.Thread | None = None


def recover_interrupted_scan() -> None:
    with _LOCK:
        job = _read_job()
        if job.get("status") != "running":
            return
        job["status"] = "interrupted"
        job["finished_at"] = _now()
        job["message"] = "The scan process stopped. Start it again to continue from the saved candles."
        _write_job(job)


def start_scan() -> tuple[int, dict]:
    credentials = _credentials()
    if credentials is None:
        return 409, {
            "status": "fail",
            "message": "Kite credentials are not on this instance. Place them in /etc/jakshwealth-parallel/kite.env and retry.",
        }
    with _LOCK:
        current = _read_job()
        if current.get("status") == "running":
            return 409, {"status": "fail", "message": "A scan is already running.", "job_id": current.get("job_id")}
        job = {
            "job_id": uuid.uuid4().hex,
            "status": "running",
            "universe": 0,
            "completed": 0,
            "triggered": 0,
            "started_at": _now(),
            "finished_at": None,
            "message": "Scan started.",
        }
        _write_job(job)
        thread = threading.Thread(target=_run, args=(job["job_id"], credentials), name="nse-scan", daemon=True)
        global _THREAD
        _THREAD = thread
        thread.start()
    return 202, job


def job_status(job_id: str) -> tuple[int, dict]:
    job = _read_job()
    if not job or job.get("job_id") != job_id:
        return 404, {"status": "fail", "message": "That scan was not found."}
    return 200, job


def _run(job_id: str, credentials: tuple[str, str]) -> None:
    try:
        from kiteconnect import KiteConnect
    except ImportError as exc:
        _finish(job_id, "failed", f"kiteconnect is not installed ({exc.__class__.__name__}).")
        return
    api_key, access_token = credentials
    kite = KiteConnect(api_key=api_key)
    kite.set_access_token(access_token)
    try:
        instruments = kite.instruments("NSE") or []
    except Exception as exc:
        _finish(job_id, "failed", _safe_message(exc))
        return
    tokens = _equity_tokens(instruments)
    cache = _read_cache()
    end = datetime.now()
    start = end - timedelta(days=HISTORY_DAYS)
    symbols = sorted(tokens)
    _update(job_id, universe=len(symbols), completed=sum(1 for symbol in symbols if symbol in cache), message="Fetching daily candles.")
    for offset, symbol in enumerate(symbols):
        if symbol in cache:
            continue
        if offset:
            time.sleep(REQUEST_GAP_SECONDS)
        try:
            raw = kite.historical_data(tokens[symbol], start, end, "day")
        except Exception as exc:
            name = exc.__class__.__name__
            if "Token" in name:
                _finish(job_id, "failed", "The Kite session expired. Scan progress is saved.")
                return
            continue
        from breakout import normalize_candles
        cache[symbol] = {"symbol": symbol, "instrument_token": tokens[symbol], "candles": normalize_candles(raw)}
        _write_cache(cache)
        _update(job_id, completed=sum(1 for item in symbols if item in cache))
    from breakout import scan_breakouts
    stocks = []
    for symbol, item in cache.items():
        if symbol not in tokens:
            continue
        stocks.append({
            "symbol": symbol,
            "company_name": symbol,
            "instrument_token": item.get("instrument_token"),
            "candles": item.get("candles") or [],
        })
    result = scan_breakouts(stocks)
    setups = [
        {key: value for key, value in setup.items() if key != "candles"}
        for setup in result["setups"]
    ]
    _write_setups(setups)
    _finish(job_id, "complete", "Scan complete.", triggered=len(setups), completed=len(symbols), universe=len(symbols))


def _equity_tokens(instruments: list) -> dict[str, int]:
    tokens = {}
    for instrument in instruments:
        if not isinstance(instrument, dict):
            continue
        if instrument.get("exchange") != "NSE" or instrument.get("instrument_type") != "EQ":
            continue
        symbol = str(instrument.get("tradingsymbol") or "").strip().upper()
        token = instrument.get("instrument_token")
        if symbol and token is not None:
            tokens[symbol] = int(token)
    return tokens


def _credentials() -> tuple[str, str] | None:
    if not CREDENTIAL_PATH.is_file():
        return None
    values = {}
    for line in CREDENTIAL_PATH.read_text(encoding="utf-8").splitlines():
        text = line.strip()
        if not text or text.startswith("#") or "=" not in text:
            continue
        key, value = text.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    api_key = values.get("KITE_API_KEY", "")
    access_token = values.get("KITE_ACCESS_TOKEN", "")
    if not api_key or not access_token:
        return None
    return api_key, access_token


def _finish(job_id: str, status: str, message: str, **fields) -> None:
    _update(job_id, status=status, message=message, finished_at=_now(), **fields)


def _update(job_id: str, **fields) -> None:
    with _LOCK:
        job = _read_job()
        if job.get("job_id") != job_id:
            return
        job.update(fields)
        _write_job(job)


def _read_job() -> dict:
    return _read_json(DATA_DIR / "job.json")


def _write_job(job: dict) -> None:
    _write_json(DATA_DIR / "job.json", job)


def _read_cache() -> dict:
    payload = _read_json(DATA_DIR / "candles.json")
    stocks = payload.get("stocks")
    return stocks if isinstance(stocks, dict) else {}


def _write_cache(stocks: dict) -> None:
    _write_json(DATA_DIR / "candles.json", {"stocks": stocks})


def _write_setups(setups: list) -> None:
    _write_json(DATA_DIR / "setups.json", {"setups": setups})


def _read_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return {}
    return payload if isinstance(payload, dict) else {}


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(payload), encoding="utf-8")
    temporary.replace(path)


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _safe_message(exc: Exception) -> str:
    message = str(exc)
    lowered = message.lower()
    if "access_token" in lowered or "api_secret" in lowered or "api_key" in lowered:
        return "Kite rejected the session."
    return message or exc.__class__.__name__
