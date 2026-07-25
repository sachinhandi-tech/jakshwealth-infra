# Personal AWS — fresh account, single environment

This project targets a **personal AWS account** with **no pre-existing resources**. There is no Route53 domain, no ACM certificate, and no dev/test/prod split — everything runs in one environment (`dev` bucket suffix).

## What gets created (in order)

| Step | Jenkins job / command | Creates |
|------|----------------------|---------|
| 1 | `jakshwealth-infra` pipeline → Bootstrap | S3: `jakshwealth-infra-dev`, `jakshwealth-artifacts-dev`, `jakshwealth-logs-dev`; DynamoDB: `terraform-state-lock` |
| 2 | `jakshwealth-infra` → UI hosting | S3: `jakshwealth-ui-dev`; CloudFront distribution (default `*.cloudfront.net` URL) |
| 3 | `jakshwealth-infra` → API Gateway | REST API `jw-api` with execute-api URL (no custom domain) |
| 4 | `jakshwealth-api` pipeline | Lambda functions + API integrations |
| 5 | `jakshwealth-ui` pipeline | Angular build → S3 sync → CloudFront invalidation |

## One-time setup

### 1. IAM user (AWS Console)

Create user `sachindad` (or similar) with programmatic access. For initial setup, `AdministratorAccess` is simplest; tighten later.

```bash
aws configure --profile jakshwealth
aws sts get-caller-identity --profile jakshwealth
```

Set `account_number` in each repo's `.cicd/build_props/build.properties`.

### 2. Jenkins EC2

As the `jenkins` user:

```bash
aws configure --profile jakshwealth   # same keys as local
terraform version                     # needs >= 1.1.9
```

Or run `scripts/install-jenkins-prerequisites.sh` from `jakshwealth-infra`.

GitHub credential ID `jakshwealth-ui` (PAT) for private repo clones.

### 3. Bootstrap (local or via infra Jenkins job)

```bash
cd jakshwealth-infra/bootstrap/terraform
terraform init
terraform apply -var-file=vars.dev.tfvars
```

`.tfvars` files use **HCL syntax** — quote strings (`deploy_env = "dev"`), not Java properties (`deploy_env=dev`).

## URLs after deploy (no custom domain)

**UI (CloudFront):**

```bash
aws cloudfront list-distributions --profile jakshwealth \
  --query "DistributionList.Items[?Origins.Items[0].Id=='S3-jakshwealth-ui-dev'].DomainName" \
  --output text
```

**API (execute-api):**

```bash
API_ID=$(aws apigateway get-rest-apis --profile jakshwealth \
  --query "items[?name=='jw-api'].id | [0]" --output text)
echo "https://${API_ID}.execute-api.us-east-1.amazonaws.com/dev/jw-api"
```

Point the Angular app at the API URL in `src/environments/environment.development.ts` (`url: '/jw-api/'` works with a dev proxy; for production build set the full execute-api base URL).

## Configuration files (single env)

| Repo | Config |
|------|--------|
| All | `.cicd/build_props/build.properties` |
| Infra UI TF | `s3-cloudfront-ssa/module/s3_config_vars/s3.dev.tfvars` (`enable_custom_domain=false`) |
| Infra API TF | `code-infra/module/main/vars.dev.tfvars` (`enable_custom_domain=false`) |
| API Lambdas | `automation_codes/terraforms/vars.dev.tfvars` (`enable_lambda_vpc=false`) |

## Optional: VPC for Lambdas

By default Lambdas run **outside** a VPC (simpler, no NAT Gateway cost). To enable VPC later:

1. Bootstrap with `create_vpc=true` in `bootstrap/terraform/vars.dev.tfvars`
2. Set `enable_lambda_vpc=true` in `user_params.json` and `vars.dev.tfvars`
3. Re-run API pipeline

## Security

- Never commit AWS keys or passwords
- Rotate any credential shared in chat
- `enable_custom_domain=false` skips Route53 and ACM entirely
