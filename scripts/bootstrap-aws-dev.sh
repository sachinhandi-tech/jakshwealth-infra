#!/usr/bin/env bash
# One-time bootstrap for JakshWealth dev: S3 state/artifact buckets + DynamoDB lock table.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=/dev/null
[[ -f "${ROOT}/aws.local.env" ]] && source "${ROOT}/aws.local.env"

export AWS_PROFILE="${AWS_PROFILE:-jakshwealth}"
export AWS_REGION="${AWS_REGION:-ap-south-2}"

ENV="${1:-dev}"
case "${AWS_REGION}" in
  ap-south-2) REGION_SUFFIX="aps2" ;;
  us-east-1)  REGION_SUFFIX="use1" ;;
  *)          REGION_SUFFIX="${AWS_REGION//-/}" ;;
esac
STATE_BUCKET="jakshwealth-infra-${ENV}-${REGION_SUFFIX}"
ARTIFACTS_BUCKET="jakshwealth-artifacts-${ENV}-${REGION_SUFFIX}"
LOGS_BUCKET="jakshwealth-logs-${ENV}-${REGION_SUFFIX}"
LOCK_TABLE="terraform-state-lock"

echo "Bootstrap AWS_PROFILE=${AWS_PROFILE} AWS_REGION=${AWS_REGION} ENV=${ENV} suffix=${REGION_SUFFIX}"

aws sts get-caller-identity

create_bucket() {
  local name="$1"
  if aws s3api head-bucket --bucket "${name}" 2>/dev/null; then
    echo "Bucket exists: ${name}"
    return 0
  fi
  echo "Creating bucket: ${name}"
  if [[ "${AWS_REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "${name}" --region "${AWS_REGION}"
  else
    aws s3api create-bucket --bucket "${name}" --region "${AWS_REGION}" \
      --create-bucket-configuration "LocationConstraint=${AWS_REGION}"
  fi
  aws s3api put-bucket-versioning --bucket "${name}" \
    --versioning-configuration Status=Enabled
  aws s3api put-public-access-block --bucket "${name}" \
    --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
}

create_bucket "${STATE_BUCKET}"
create_bucket "${ARTIFACTS_BUCKET}"
create_bucket "${LOGS_BUCKET}"

if aws dynamodb describe-table --table-name "${LOCK_TABLE}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "DynamoDB table exists: ${LOCK_TABLE}"
else
  echo "Creating DynamoDB table: ${LOCK_TABLE}"
  aws dynamodb create-table \
    --table-name "${LOCK_TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${AWS_REGION}"
  aws dynamodb wait table-exists --table-name "${LOCK_TABLE}" --region "${AWS_REGION}"
fi

echo ""
echo "Bootstrap complete. Buckets:"
echo "  ${STATE_BUCKET}     (Terraform state)"
echo "  ${ARTIFACTS_BUCKET}  (Lambda zips + API Terraform state)"
echo "  ${LOGS_BUCKET}        (CloudFront / access logs)"
echo "  ${LOCK_TABLE}        (state lock)"
echo ""
echo "Next:"
echo "  cd s3-cloudfront-ssa/module"
echo "  terraform init -backend-config=config/${ENV}-backend.tfvars"
echo "  terraform plan -var deploy_env=${ENV} -var-file=s3_config_vars/s3.${ENV}.tfvars"
