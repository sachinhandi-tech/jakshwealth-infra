# Personal AWS — fresh account, single environment

This project targets a **personal AWS account** with **no pre-existing resources**. There is no Route53 domain, no ACM certificate, and no dev/test/prod split — everything runs in one environment (`dev` bucket suffix).

All resources deploy to **`ap-south-2` (Hyderabad)**. Set the same region on Jenkins and local AWS profile:

```bash
aws configure set region ap-south-2 --profile jakshwealth
```

If you previously created buckets in `us-east-1`, bootstrap again in `ap-south-2` (new S3 bucket names in the new region) or destroy old resources first.

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
chmod +x import-existing.sh
./import-existing.sh dev terraform-state-lock
terraform apply -var-file=vars.dev.tfvars
```

If you previously ran `scripts/bootstrap-aws-dev.sh`, the import step adopts those resources into Terraform state so apply does not fail with "already exists".

`.tfvars` files use **HCL syntax** — quote strings (`deploy_env = "dev"`), not Java properties (`deploy_env=dev`).

## Terraform state locks (local laptop vs Jenkins)

All stacks share one DynamoDB table: `terraform-state-lock`. Terraform records **OS user@hostname** in the lock (e.g. `c8r4vx@ML6KWN7Y13` from a Mac plan), **not** the IAM user (`sachindad`). Jenkins runs as the `jenkins` OS user on EC2, so its locks show `jenkins@...`.

**Only run Terraform from Jenkins** for deploys. Do not run `terraform plan/apply` locally against the shared S3 backend.

If a laptop lock blocks Jenkins, delete it once:

```bash
AWS_PROFILE=jakshwealth AWS_REGION=ap-south-2 aws dynamodb delete-item \
  --table-name terraform-state-lock \
  --key '{"LockID":{"S":"jakshwealth-infra-dev/dev/jakshwealth-ui-infra/terraform.tfstate"}}'
```

Or remove all non-jenkins / stale locks:

```bash
AWS_PROFILE=jakshwealth REMOVE_NON_JENKINS=1 ./scripts/terraform-unlock-stale.sh 5
```

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
echo "https://${API_ID}.execute-api.ap-south-2.amazonaws.com/dev/jw-api"
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
