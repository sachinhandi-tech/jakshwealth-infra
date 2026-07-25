# Personal AWS account setup (jakshu2024@gmail.com)

**Important:** Your AWS **console password is not used** by Terraform, Jenkins, or the AWS CLI.
Create an **IAM user** with programmatic access (Access Key ID + Secret Access Key).

## 1. One-time IAM setup (AWS Console)

Sign in at https://console.aws.amazon.com with your root email.

1. **IAM → Users → Create user** — e.g. `jakshwealth-deploy`
2. Attach policies (start broad for dev; tighten later):
   - `AdministratorAccess` *(dev only)* OR custom policy for Lambda, API Gateway, S3, CloudFront, Route53, Secrets Manager, IAM
3. **Security credentials → Create access key** → CLI
4. Save **Access Key ID** and **Secret Access Key** (shown once)

## 2. Configure AWS CLI profile (all repos use `jakshwealth`)

```bash
aws configure --profile jakshwealth
# AWS Access Key ID:     <paste>
# AWS Secret Access Key: <paste>
# Default region:        us-east-1
# Default output format: json

aws sts get-caller-identity --profile jakshwealth
```

Copy the `Account` value (12 digits) into each repo's `.cicd/build_props/*-build.properties` as `account_number=`.

## 3. Optional local env file (gitignored)

```bash
cp aws.local.env.example aws.local.env
# Edit AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY only if not using ~/.aws/credentials
```

## 4. Bootstrap S3 + DynamoDB (once per env)

```bash
chmod +x scripts/bootstrap-aws-dev.sh
./scripts/bootstrap-aws-dev.sh dev
```

Creates `jakshwealth-infra-dev`, `jakshwealth-artifacts-dev`, and `terraform-state-lock`.

## 5. S3 buckets created by Terraform (UI hosting)

## Security

- **Never commit** passwords, access keys, or `aws.local.env`
- **Rotate** any credential shared in chat or logs
- Prefer IAM user keys over root console password for automation
