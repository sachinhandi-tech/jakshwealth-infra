"""HTTP service for the parallel NSE scan. Binds only the test port."""

from __future__ import annotations

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from breakout import scan_breakouts, self_test_fixture
from market import job_status, recover_interrupted_scan, start_scan

HOST = "0.0.0.0"
PORT = 8080


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self) -> None:
        path = self.path.split("?", 1)[0]
        if path == "/health":
            self._send(200, {"status": "ok", "service": "nse-scan", "environment": "Parallel-Test"})
            return
        if path.startswith("/scans/"):
            code, body = job_status(path.removeprefix("/scans/"))
            self._send(code, body)
            return
        self._send(404, {"status": "fail", "message": "Not found."})

    def do_POST(self) -> None:
        path = self.path.split("?", 1)[0]
        if path == "/logic/self-test":
            body = _self_test()
            self._send(200 if body["status"] == "pass" else 500, body)
            return
        if path == "/scans":
            code, body = start_scan()
            self._send(code, body)
            return
        self._send(404, {"status": "fail", "message": "Not found."})

    def log_message(self, fmt: str, *args) -> None:
        print("%s %s" % (self.address_string(), fmt % args), flush=True)

    def _send(self, status: int, body: dict) -> None:
        encoded = json.dumps(body).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)


def _self_test() -> dict:
    result = scan_breakouts(self_test_fixture())
    setups = result["setups"]
    passed = (
        result["scanned"] == 2
        and len(setups) == 1
        and setups[0]["symbol"] == "INFY"
        and setups[0]["breakout_low"] == 90
        and setups[0]["days_since"] == 4
    )
    return {
        "status": "pass" if passed else "fail",
        "triggered": len(setups),
        "symbol": None if not setups else setups[0]["symbol"],
        "breakout_low": None if not setups else setups[0]["breakout_low"],
        "days_since": None if not setups else setups[0]["days_since"],
        "scanned": result["scanned"],
    }


def main() -> None:
    recover_interrupted_scan()
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"nse-scan listening on {HOST}:{PORT}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
