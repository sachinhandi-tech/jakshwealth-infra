# JakshWealth UI — S3 + CloudFront + Route53

Hosts the **jakshwealth-ui** Angular SPA (same pattern as the upstream SSA UI stack).

## Resources per environment

| Resource | Name pattern |
|----------|--------------|
| S3 bucket | `jakshwealth-ui-{env}` |
| CloudFront origin ID | `S3-jakshwealth-ui-{env}` |
| Route53 / CF alias | `jw-ui.jakshwealth-{env}.example.com` (configure in tfvars) |
| Terraform state key | `{env}/jakshwealth-ui-infra/terraform.tfstate` |

## Deploy

Applied from **jakshwealth-infra** Jenkins pipeline (`s3-cloudfront-ssa/module`).

```bash
cd s3-cloudfront-ssa/module
terraform init -backend-config=config/dev-backend.tfvars
terraform plan -var deploy_env=dev -var-file=s3_config_vars/s3.dev.tfvars
terraform apply
```

## UI release

**jakshwealth-ui** Jenkins syncs `dist/browser/` to the S3 bucket and invalidates CloudFront.
