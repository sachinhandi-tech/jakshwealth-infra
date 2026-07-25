#!/usr/bin/env bash
# Remove stale Terraform state locks from DynamoDB (e.g. left by a local plan on a laptop).
# Safe when Jenkins uses disableConcurrentBuilds and locks are older than STALE_MINUTES.
set -euo pipefail

STALE_MINUTES="${1:-30}"
TABLE="${TERRAFORM_LOCK_TABLE:-terraform-state-lock}"
REGION="${AWS_REGION:-us-east-1}"

echo "Checking ${TABLE} for locks older than ${STALE_MINUTES} minutes..."

export STALE_MINUTES TABLE REGION
export SCAN_JSON
SCAN_JSON=$(aws dynamodb scan --table-name "${TABLE}" --region "${REGION}" --output json 2>/dev/null || echo '{"Items":[]}')

REMOVED=$(python3 <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone, timedelta

stale_minutes = int(os.environ["STALE_MINUTES"])
table = os.environ["TABLE"]
region = os.environ["REGION"]
payload = json.loads(os.environ["SCAN_JSON"])
now = datetime.now(timezone.utc)
cutoff = now - timedelta(minutes=stale_minutes)
removed = 0

for item in payload.get("Items", []):
    lock_id = item["LockID"]["S"]
    info = json.loads(item["Info"]["S"])
    created_raw = info.get("Created", "")
    who = info.get("Who", "unknown")
    try:
        created = datetime.strptime(created_raw.replace(" UTC", ""), "%Y-%m-%d %H:%M:%S.%f %z")
    except ValueError:
        print(f"Skip (unparseable Created): {lock_id} who={who}", file=sys.stderr)
        continue

    if created > cutoff:
        print(f"Keep active lock ({who}): {lock_id}", file=sys.stderr)
        continue

    subprocess.run(
        [
            "aws", "dynamodb", "delete-item",
            "--table-name", table,
            "--region", region,
            "--key", json.dumps({"LockID": {"S": lock_id}}),
        ],
        check=True,
    )
    print(f"Removed stale lock ({who}, created {created_raw}): {lock_id}", file=sys.stderr)
    removed += 1

print(removed)
PY
)

echo "Stale lock cleanup done (removed: ${REMOVED})."
