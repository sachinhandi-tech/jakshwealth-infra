# jakshwealth-infra

Terraform and reusable modules for **jakshwealth-api** and **jakshwealth-ui** only.

This repo is a trimmed fork of `ccd-infrastructure` — CCD calc pipelines, EC2 API, RDS, websocket API, and platform UI stacks were removed.

## Layout

```
jakshwealth-infra/
├── bootstrap/                        # Foundation S3 buckets for Terraform state and artifacts
├── s3-cloudfront-ui/               # jakshwealth-ui S3 + CloudFront + Route53
├── ec2-algo-infra/                 # EC2 infrastructure for kite-algo-setup (ALB, ASG, CloudFront)
├── postgres/                       # RDS PostgreSQL for subscriber data
└── Jenkinsfile                      # Platform infra (UI + EC2)
```

## What each app uses

| App | Infra from this repo |
|-----|----------------------|
| **jakshwealth-ui** | `s3-cloudfront-ui/module` → S3 bucket, CloudFront, DNS |
| **jakshwealth-api** | `ec2-algo-infra` → EC2, ALB, CloudFront for API |

## Deploy order (per environment)

1. **Platform** — run this repo's Jenkinsfile (or Terraform manually):
   - `bootstrap/terraform` — Foundation S3 buckets
   - `s3-cloudfront-ui/module` — UI hosting
   - `postgres` — RDS PostgreSQL
   - `ec2-algo-infra` — EC2 infrastructure (ALB, ASG, CloudFront)
2. **API app** — run **jakshwealth-api** Jenkinsfile (publish EC2 API bundle to S3)
3. **UI app** — run **jakshwealth-ui** Jenkinsfile (build → S3 sync → CF invalidation)

## Personal AWS (fresh account, single environment)

**Start here:** [docs/PERSONAL_DEPLOY.md](docs/PERSONAL_DEPLOY.md) — bootstrap from scratch, no Route53, no dev/test/prod split.

**Setup:** [docs/AWS_PERSONAL_SETUP.md](docs/AWS_PERSONAL_SETUP.md) — IAM user + `aws configure --profile jakshwealth`

- VPC + subnets for EC2 (managed by ec2-algo-infra)
- Route53 hosted zone + ACM certificates
- S3 buckets: `jakshwealth-artifacts-{env}`, `jakshwealth-infra-{env}` (state), `jakshwealth-ui-{env}`
- Secrets Manager: `{env}/jakshwealth/config`
- IAM role: EC2 instance profile with Secrets Manager access

## EC2 Deployment

The EC2 instances in `ec2-algo-infra` automatically:
- Pull API bundles from S3 every 60 seconds
- Install and restart services when new bundles are detected
- Publish API base URL to S3 for UI discovery

See `ec2-algo-infra/user_data.sh.tftpl` for bootstrap configuration.
