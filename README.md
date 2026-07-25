# jakshwealth-infra

Terraform and reusable modules for **jakshwealth-api** and **jakshwealth-ui** only.

This repo is a trimmed fork of `ccd-infrastructure` — CCD calc pipelines, EC2 API, RDS, websocket API, and platform UI stacks were removed.

## Layout

```
jakshwealth-infra/
├── deploy/                          # Reusable modules (consumed by jakshwealth-api)
│   ├── lambda/
│   ├── api-gateway-resource/
│   ├── api-gateway-integration-jw/
│   └── api-lambda-permission/
├── code-infra/
│   ├── api-gateway/                 # jw-api REST API shell + TOKEN authorizer wiring
│   └── module/main/                 # Apply API Gateway platform per environment
├── s3-cloudfront-ssa/               # jakshwealth-ui S3 + CloudFront + Route53
└── Jenkinsfile                      # Platform infra (UI + API GW shell)
```

## What each app uses

| App | Infra from this repo |
|-----|----------------------|
| **jakshwealth-ui** | `s3-cloudfront-ssa/module` → S3 bucket, CloudFront, DNS |
| **jakshwealth-api** | `deploy/*` modules + `code-infra/module/main` (API GW + authorizer) |

## Deploy order (per environment)

1. **Platform** — run this repo's Jenkinsfile (or Terraform manually):
   - `s3-cloudfront-ssa/module` — UI hosting
   - `code-infra/module/main` — `jw-api` REST API + authorizer IAM
2. **API app** — run **jakshwealth-api** Jenkinsfile (Lambdas, integrations, stage)
3. **UI app** — run **jakshwealth-ui** Jenkinsfile (build → S3 sync → CF invalidation)

## Personal AWS (fresh account, single environment)

**Start here:** [docs/PERSONAL_DEPLOY.md](docs/PERSONAL_DEPLOY.md) — bootstrap from scratch, no Route53, no dev/test/prod split.

**Setup:** [docs/AWS_PERSONAL_SETUP.md](docs/AWS_PERSONAL_SETUP.md) — IAM user + `aws configure --profile jakshwealth`

- VPC + subnets tagged for Lambda (see jakshwealth-api `static_data.tf`)
- Route53 hosted zone + ACM certificates
- S3 buckets: `jakshwealth-artifacts-{env}`, `jakshwealth-infra-{env}` (state), `jakshwealth-ui-{env}`
- Secrets Manager: `{env}/jakshwealth/config`
- IAM policy: `jakshwealth-lambda-secrets` (Secrets Manager read for Lambdas)

## Local module path for jakshwealth-api

From a sibling checkout:

```
../jakshwealth-infra/deploy/lambda
../jakshwealth-infra/deploy/api-gateway-integration-jw
```

See `jakshwealth-api/automation_codes/module_sources/sources.json`.
