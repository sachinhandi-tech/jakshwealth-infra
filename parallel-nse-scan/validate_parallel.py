"""Find the parallel scan load balancer by name and report PASS or FAIL."""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError

NAME = "kite-algo-setup"
ENVIRONMENT = "Parallel-Test"
PORT = 80


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate the parallel NSE scan instance.")
    parser.add_argument("--region", default="ap-south-2")
    parser.add_argument("--profile", default="jakshwealth")
    parser.add_argument("--attempts", type=int, default=30)
    parser.add_argument("--interval-seconds", type=float, default=10)
    args = parser.parse_args()

    try:
        session = boto3.Session(profile_name=args.profile, region_name=args.region)
        elbv2 = session.client("elbv2", config=Config(retries={"max_attempts": 3, "mode": "standard"}))
        response = elbv2.describe_load_balancers(Names=[NAME])
    except (BotoCoreError, ClientError) as exc:
        return _fail(f"Could not describe the load balancer: {exc.__class__.__name__}")

    balancers = response.get("LoadBalancers", [])
    if len(balancers) != 1:
        return _fail(f"Expected 1 load balancer named {NAME} and found {len(balancers)}.")

    dns_name = balancers[0].get("DNSName")
    print(f"LOAD_BALANCER {dns_name}")
    if not dns_name:
        return _fail("The load balancer has no DNS name.")

    health = _retry(dns_name, "/health", "GET", args.attempts, args.interval_seconds)
    if health is None:
        return _fail("Health check did not return HTTP 200.")
    print(f"HEALTH {health['status_code']} {health['body'].get('status')}")
    if health["status_code"] != 200 or health["body"].get("status") != "ok" or health["body"].get("environment") != ENVIRONMENT:
        return _fail("Health payload did not match.")

    logic = _request(dns_name, "/logic/self-test", "POST")
    if logic is None:
        return _fail("Self-test request failed.")
    print(
        f"SELF_TEST {logic['status_code']} {logic['body'].get('status')} "
        f"triggered={logic['body'].get('triggered')} symbol={logic['body'].get('symbol')}"
    )
    if logic["status_code"] != 200 or logic["body"].get("status") != "pass" or logic["body"].get("triggered") != 1:
        return _fail("Breakout self-test did not pass.")
    if logic["body"].get("symbol") != "INFY" or logic["body"].get("breakout_low") != 90 or logic["body"].get("days_since") != 4:
        return _fail("Breakout self-test payload did not match the desk fixture.")

    print("RESULT PASS")
    return 0


def _retry(ip: str, path: str, method: str, attempts: int, interval: float):
    for attempt in range(1, attempts + 1):
        result = _request(ip, path, method)
        if result is not None and result["status_code"] == 200:
            return result
        print(f"WAIT {attempt}/{attempts} {path}")
        time.sleep(interval)
    return None


def _request(ip: str, path: str, method: str):
    request = urllib.request.Request(f"http://{ip}:{PORT}{path}", method=method)
    try:
        with urllib.request.urlopen(request, timeout=5) as response:
            raw = response.read().decode("utf-8")
            return {"status_code": response.status, "body": json.loads(raw)}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="replace")
        try:
            body = json.loads(raw)
        except json.JSONDecodeError:
            body = {"status": "fail", "message": raw}
        return {"status_code": exc.code, "body": body}
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError, OSError):
        return None


def _fail(message: str) -> int:
    print(f"ERROR {message}")
    print("RESULT FAIL")
    return 1


if __name__ == "__main__":
    sys.exit(main())
