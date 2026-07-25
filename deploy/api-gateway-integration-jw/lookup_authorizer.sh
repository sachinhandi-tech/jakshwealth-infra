#!/usr/bin/env bash
# Resolve jw_authorization authorizer id from the live jw-api REST API (no Terraform remote state).
set -euo pipefail

API_NAME="${JW_API_NAME:-jw-api}"
AUTHORIZER_NAME="${JW_AUTHORIZER_NAME:-jw_authorization}"

API_ID=$(aws apigateway get-rest-apis \
  --query "items[?name=='${API_NAME}'].id | [0]" \
  --output text)

if [[ -z "${API_ID}" || "${API_ID}" == "None" ]]; then
  echo "jw-api REST API not found. Run jakshwealth-infra Jenkins (API Gateway platform stage) first." >&2
  exit 1
fi

AUTHORIZER_ID=$(aws apigateway get-authorizers \
  --rest-api-id "${API_ID}" \
  --query "items[?name=='${AUTHORIZER_NAME}'].id | [0]" \
  --output text)

if [[ -z "${AUTHORIZER_ID}" || "${AUTHORIZER_ID}" == "None" ]]; then
  echo "Authorizer ${AUTHORIZER_NAME} not found on ${API_NAME}. Run jakshwealth-infra Jenkins (API Gateway platform stage) first." >&2
  exit 1
fi

python3 - <<PY
import json
print(json.dumps({"authorizer_id": "${AUTHORIZER_ID}"}))
PY
