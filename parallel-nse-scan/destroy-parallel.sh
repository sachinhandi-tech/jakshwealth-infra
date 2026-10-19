#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

versions="$(cat versions.tf)"
case "$versions" in
  *'backend "local"'*) ;;
  *) echo "Refusing to destroy: this directory is not the local parallel-test state." >&2; exit 1 ;;
esac
case "$versions" in
  *parallel-test.tfstate*) ;;
  *) echo "Refusing to destroy: parallel-test.tfstate is not the configured backend." >&2; exit 1 ;;
esac
case "$versions" in
  *jakshwealth-infra-dev*|*terraform-state-lock*)
    echo "Refusing to destroy: production backend settings are present." >&2
    exit 1
    ;;
esac

if [[ ! -f parallel-test.tfstate ]]; then
  echo "Refusing to destroy: parallel-test.tfstate is not in this directory." >&2
  exit 1
fi

state="$(cat parallel-test.tfstate)"
for token in jakshwealth-infra-dev jw_kite terraform-state-lock aws_lambda_function aws_db_instance aws_cloudfront_distribution; do
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
