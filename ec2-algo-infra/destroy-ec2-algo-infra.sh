#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

backend="$(cat backend.dev.tfvars)"
case "$backend" in
  *'dev/parallel-nse-scan/terraform.tfstate'*) ;;
  *) echo "Refusing to destroy: backend key is not dev/parallel-nse-scan/terraform.tfstate." >&2; exit 1 ;;
esac
for token in "dev/jakshwealth/terraform.tfstate" "dev/jakshwealth-postgres/terraform.tfstate"; do
  if [[ "$backend" == *"$token"* ]]; then
    echo "Refusing to destroy: backend points at production state $token." >&2
    exit 1
  fi
done

terraform init -input=false -reconfigure -backend-config="backend.dev.tfvars"
state="$(terraform state pull)"
for token in aws_lambda_function aws_db_instance aws_cloudfront_distribution jw_kite; do
  if [[ "$state" == *"$token"* ]]; then
    echo "Refusing to destroy: state contains production marker $token." >&2
    exit 1
  fi
done
if [[ "$state" != *"Parallel-Test"* ]]; then
  echo "Refusing to destroy: state has no Parallel-Test resources." >&2
  exit 1
fi

terraform destroy -input=false "$@"
