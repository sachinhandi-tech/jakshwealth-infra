# Personal AWS account setup

**Single environment only** — see [PERSONAL_DEPLOY.md](./PERSONAL_DEPLOY.md) for the full deploy order.

Your AWS **console password is not used** by Terraform, Jenkins, or the CLI. Use an IAM user with programmatic access.

## 1. IAM user (one-time)

1. **IAM → Users → Create user** — e.g. `sachindad`
2. Attach `AdministratorAccess` for initial personal setup (tighten later)
3. **Create access key** → CLI
4. Save Access Key ID and Secret Access Key

## 2. AWS CLI profile

```bash
aws configure --profile jakshwealth
# Region: ap-south-2

aws sts get-caller-identity --profile jakshwealth
```

Copy the `Account` value into `.cicd/build_props/build.properties` as `account_number=`.

## 3. Bootstrap (creates S3 + DynamoDB lock)

```bash
cd bootstrap/terraform
terraform init
terraform apply -var-file=vars.dev.tfvars
```

Or run the **jakshwealth-infra** Jenkins pipeline with `TERRAFORM_ACTION=apply` (bootstrap stage runs automatically).

## 4. No Route53 / custom domain

All Terraform uses `enable_custom_domain=false`. You get:

- UI: `https://<id>.cloudfront.net`
- API: `https://<api-id>.execute-api.ap-south-2.amazonaws.com/dev/jw-api`

## Security

- Never commit passwords, access keys, or `aws.local.env`
- Rotate credentials if they were ever shared in chat or logs
