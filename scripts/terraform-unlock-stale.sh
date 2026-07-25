#!/usr/bin/env bash
# Remove stale Terraform state locks from DynamoDB (e.g. left by a local plan on a laptop).
# Jenkins sets REMOVE_NON_JENKINS=1 to drop locks held by non-jenkins machines immediately.
set -euo pipefail

STALE_MINUTES="${1:-30}"
TABLE="${TERRAFORM_LOCK_TABLE:-terraform-state-lock}"
REGION="${AWS_REGION:-us-east-1}"
REMOVE_NON_JENKINS="${REMOVE_NON_JENKINS:-0}"

echo "Checking ${TABLE} (stale>${STALE_MINUTES}m, remove_non_jenkins=${REMOVE_NON_JENKINS})..."

export STALE_MINUTES TABLE REGION REMOVE_NON_JENKINS
export SCAN_JSON
SCAN_JSON=$(aws dynamodb scan --table-name "${TABLE}" --region "${REGION}" --output json 2>/dev/null || echo '{"Items":[]}')

REMOVED=$(python3 <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone, timedelta

stale_minutes = int(os.environ["STALE_MINUTES"])
remove_non_jenkins = os.environ.get("REMOVE_NON_JENKINS", "0") == "1"
table = os.environ["TABLE"]
region = os.environ["REGION"]
payload = json.loads(os.environ["SCAN_JSON"])
now = datetime.now(timezone.utc)
cutoff = now - timedelta(minutes=stale_minutes)
removed = 0


def delete_lock(lock_id: str, reason: str) -> None:
    global removed
    subprocess.run(
        [
            "aws", "dynamodb", "delete-item",
            "--table-name", table,
            "--region", region,
            "--key", json.dumps({"LockID": {"S": lock_id}}),
        ],
        check=True,
    )
    print(f"Removed lock — {reason}: {lock_id}", file=sys.stderr)
    removed += 1


def parse_created(raw: str) -> datetime:
    raw = raw.strip().replace(" UTC", "")
    if raw.endswith("Z"):
        raw = raw[:-1] + "+00:00"
    try:
        return datetime.fromisoformat(raw)
    except ValueError:
        return datetime.strptime(raw, "%Y-%m-%d %H:%M:%S.%f %z")


for item in payload.get("Items", []):
    lock_id = item.get("LockID", {}).get("S")
    if not lock_id:
        print("Skip item without LockID", file=sys.stderr)
        continue

    info_raw = item.get("Info", {}).get("S")
    if not info_raw:
        delete_lock(lock_id, "missing Info metadata (orphan lock row)")
        continue

    try:
        info = json.loads(info_raw)
    except json.JSONDecodeError:
        delete_lock(lock_id, "invalid Info JSON")
        continue

    created_raw = info.get("Created", "")
    who = info.get("Who", "unknown")
    is_jenkins = "jenkins" in who.lower()

    if not created_raw:
        delete_lock(lock_id, f"missing Created timestamp ({who})")
        continue

    try:
        created = parse_created(created_raw)
    except ValueError:
        print(f"Skip (unparseable Created): {lock_id} who={who}", file=sys.stderr)
        continue

    if remove_non_jenkins and not is_jenkins:
        delete_lock(lock_id, f"non-jenkins holder ({who})")
    elif created > cutoff:
        print(f"Keep active lock ({who}): {lock_id}", file=sys.stderr)
    else:
        delete_lock(lock_id, f"stale ({who}, created {created_raw})")

print(removed)
PY
)

echo "Stale lock cleanup done (removed: ${REMOVED})."
