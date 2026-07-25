#!/usr/bin/env bash
# Import foundation S3 buckets and DynamoDB lock table when they already exist in AWS
# (e.g. created by scripts/bootstrap-aws-dev.sh) but are not yet in Terraform state.
set -euo pipefail

DEPLOY_ENV="${1:-dev}"
LOCK_TABLE="${2:-terraform-state-lock}"

import_if_missing() {
  local addr="$1"
  local id="$2"

  if terraform state show "${addr}" >/dev/null 2>&1; then
    echo "Already in state: ${addr}"
    return 0
  fi

  echo "Importing ${addr} <- ${id}"
  terraform import "${addr}" "${id}"
}

echo "Checking for existing foundation resources (deploy_env=${DEPLOY_ENV})..."

declare -A BUCKETS=(
  [infra]="jakshwealth-infra-${DEPLOY_ENV}"
  [artifacts]="jakshwealth-artifacts-${DEPLOY_ENV}"
  [logs]="jakshwealth-logs-${DEPLOY_ENV}"
)

for key in infra artifacts logs; do
  bucket="${BUCKETS[${key}]}"
  if aws s3api head-bucket --bucket "${bucket}" 2>/dev/null; then
    import_if_missing "aws_s3_bucket.foundation[\"${key}\"]" "${bucket}"
  else
    echo "Bucket not found (will be created): ${bucket}"
  fi
done

if aws dynamodb describe-table --table-name "${LOCK_TABLE}" >/dev/null 2>&1; then
  import_if_missing 'aws_dynamodb_table.terraform_state_lock[0]' "${LOCK_TABLE}"
else
  echo "DynamoDB table not found (will be created): ${LOCK_TABLE}"
fi

echo "Import check complete."
