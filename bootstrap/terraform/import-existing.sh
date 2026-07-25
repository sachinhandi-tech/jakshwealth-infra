#!/usr/bin/env bash
# Import foundation S3 buckets and DynamoDB lock table when they already exist in AWS
# (e.g. created by scripts/bootstrap-aws-dev.sh) but are not yet in Terraform state.
set -euo pipefail

DEPLOY_ENV="${1:-dev}"
LOCK_TABLE="${2:-terraform-state-lock}"
AWS_REGION="${AWS_REGION:-ap-south-2}"

case "${AWS_REGION}" in
  ap-south-2) REGION_SUFFIX="aps2" ;;
  us-east-1)  REGION_SUFFIX="use1" ;;
  *)          REGION_SUFFIX="${AWS_REGION//-/}" ;;
esac

bucket_name() {
  local kind="$1"
  echo "jakshwealth-${kind}-${DEPLOY_ENV}-${REGION_SUFFIX}"
}

bucket_region() {
  local bucket="$1"
  local region
  region=$(aws s3api get-bucket-location --bucket "${bucket}" --output text 2>/dev/null || echo "")
  if [[ -z "${region}" || "${region}" == "None" || "${region}" == "null" ]]; then
    echo "us-east-1"
  else
    echo "${region}"
  fi
}

import_if_missing() {
  local addr="$1"
  local id="$2"

  if terraform state show "${addr}" >/dev/null 2>&1; then
    echo "Already in state: ${addr}"
    return 0
  fi

  echo "Importing ${addr} <- ${id}"
  terraform import -input=false "${addr}" "${id}"
}

remove_from_state_if_present() {
  local addr="$1"
  if terraform state show "${addr}" >/dev/null 2>&1; then
    echo "Removing from state (wrong region or re-bootstrap): ${addr}"
    terraform state rm "${addr}" >/dev/null 2>&1 || true
  fi
}

purge_wrong_region_foundation_state() {
  local key bucket addr region
  for key in infra artifacts logs; do
    bucket="$(bucket_name "${key}")"
    addr="aws_s3_bucket.foundation[\"${key}\"]"
    if terraform state show "${addr}" >/dev/null 2>&1; then
      region=$(bucket_region "${bucket}")
      if [[ "${region}" != "${AWS_REGION}" ]]; then
        echo "Bucket ${bucket} is in ${region}, target is ${AWS_REGION} — clearing bootstrap state for ${key}"
        remove_from_state_if_present "${addr}"
        remove_from_state_if_present "aws_s3_bucket_versioning.foundation[\"${key}\"]"
        remove_from_state_if_present "aws_s3_bucket_public_access_block.foundation[\"${key}\"]"
        remove_from_state_if_present "aws_s3_bucket_server_side_encryption_configuration.foundation[\"${key}\"]"
      fi
    fi
  done
}

echo "Checking foundation resources (deploy_env=${DEPLOY_ENV}, region=${AWS_REGION}, suffix=${REGION_SUFFIX})..."

purge_wrong_region_foundation_state

declare -A BUCKETS=(
  [infra]="$(bucket_name infra)"
  [artifacts]="$(bucket_name artifacts)"
  [logs]="$(bucket_name logs)"
)

for key in infra artifacts logs; do
  bucket="${BUCKETS[${key}]}"
  if aws s3api head-bucket --bucket "${bucket}" 2>/dev/null; then
    region=$(bucket_region "${bucket}")
    if [[ "${region}" != "${AWS_REGION}" ]]; then
      echo "Skip import — ${bucket} is in ${region}, expected ${AWS_REGION}"
      continue
    fi
    import_if_missing "aws_s3_bucket.foundation[\"${key}\"]" "${bucket}"
  else
    echo "Bucket not found (will be created): ${bucket}"
  fi
done

if aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  import_if_missing 'aws_dynamodb_table.terraform_state_lock[0]' "${LOCK_TABLE}"
else
  echo "DynamoDB table not found in ${AWS_REGION} (will be created): ${LOCK_TABLE}"
fi

echo "Import check complete."
