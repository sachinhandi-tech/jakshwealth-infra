#!/usr/bin/env bash
# Adopt manually created jakshwealth.com UI hosting into Terraform state.
# Run from repo root after: cd s3-cloudfront-ui/module && terraform init -reconfigure (no profile in backend).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODULE="${ROOT}/s3-cloudfront-ui/module"
VARFILE="s3_config_vars/s3.dev.tfvars"
MOD="module.jakshwealth-ui-infra"
BUCKET="jakshwealth.com"
CF_ID="E2TQ76Z4FZC0WK"

export PATH="/opt/homebrew/Cellar/terraform/1.11.4/bin:${PATH}"
unset AWS_PROFILE

cd "${MODULE}"

terraform init -input=false -reconfigure \
  -backend-config="bucket=jakshwealth-infra-dev-aps2" \
  -backend-config="key=dev/jakshwealth-ui-infra/terraform.tfstate" \
  -backend-config="region=ap-south-2" \
  -backend-config="dynamodb_table=terraform-state-lock" \
  -backend-config="skip_region_validation=true"

import_if_missing() {
  local addr="$1"
  local id="$2"
  if terraform state show "${addr}" >/dev/null 2>&1; then
    echo "Already in state: ${addr}"
  else
    terraform import -var="deploy_env=dev" -var-file="${VARFILE}" "${addr}" "${id}"
  fi
}

# Drop legacy jakshwealth-ui-dev-aps2 resources if still present.
for legacy in \
  "${MOD}.aws_s3_bucket_policy.ui_website_bucket_plcy" \
  "${MOD}.aws_s3_bucket_acl.jakshwealth-ui-website-acl" \
  "${MOD}.aws_s3_bucket_lifecycle_configuration.ui_website_bucket_life_config" \
  "${MOD}.aws_s3_bucket_metric.jakshwealth-ui-website_metric" \
  "${MOD}.aws_s3_bucket_ownership_controls.jakshwealth-ui-website-ownership-controls" \
  "${MOD}.aws_s3_bucket_server_side_encryption_configuration.ui_website_bucket_enc_config" \
  "${MOD}.aws_s3_bucket_versioning.ui_website_bucket_versioning" \
  "${MOD}.aws_cloudfront_origin_access_identity.jakshwealth-ui-OAI" \
  "${MOD}.aws_s3_bucket.jakshwealth-ui-website"
do
  if terraform state show "${legacy}" 2>/dev/null | grep -q 'jakshwealth-ui-dev-aps2'; then
    terraform state rm "${legacy}" || true
  fi
done

import_if_missing "${MOD}.aws_s3_bucket.jakshwealth-ui-website" "${BUCKET}"
import_if_missing "${MOD}.aws_cloudfront_distribution.jakshwealth-ui" "${CF_ID}"
import_if_missing "${MOD}.aws_s3_bucket_ownership_controls.jakshwealth-ui-website-ownership-controls" "${BUCKET}"
import_if_missing "${MOD}.aws_s3_bucket_website_configuration.ui_website_bucket_website[0]" "${BUCKET}"
import_if_missing "${MOD}.aws_s3_bucket_versioning.ui_website_bucket_versioning" "${BUCKET}"
import_if_missing "${MOD}.aws_s3_bucket_server_side_encryption_configuration.ui_website_bucket_enc_config" "${BUCKET}"

echo "Import complete. Run: terraform apply -var deploy_env=dev -var-file=${VARFILE}"
