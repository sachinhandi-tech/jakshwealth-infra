# Jenkins setup (JakshWealth)

## 1. GitHub (private repos)

**Manage Jenkins → Credentials → Add**

| Field | Value |
|-------|--------|
| Kind | Username with password |
| Username | `sachinhandi-tech` |
| Password | GitHub Personal Access Token (not login password) |
| ID | `github-sachinhandi-tech` |

Use this credential in each multibranch pipeline under **Branch Sources**.

---

## 2. AWS (Terraform + S3 deploy)

**Console login password cannot be used by Jenkins, Terraform, or AWS CLI.**

Use IAM user **`sachindad`** programmatic access keys:

1. AWS Console → IAM → Users → **sachindad** → Security credentials
2. **Create access key** → CLI
3. In Jenkins: **Manage Jenkins → Credentials → Add**

| Field | Value |
|-------|--------|
| Kind | **AWS Credentials** |
| ID | `jakshwealth-aws` |
| Access Key ID | from step 2 |
| Secret Access Key | from step 2 |

All JakshWealth Jenkinsfiles bind credential ID `jakshwealth-aws` (see `.cicd/build_props/*.properties`).

Verify on Jenkins server after saving:

```bash
# Jenkins writes ~/.aws/credentials during the build; manual test:
aws sts get-caller-identity --profile jakshwealth
```

---

## 3. Tools on Jenkins server

- Node.js 20+ / npm (UI)
- Python 3 (API)
- Terraform 1.1.9+
- AWS CLI v2
- git

---

## 4. Deploy order

1. **jakshwealth-infra** — S3, CloudFront, API Gateway shell
2. **jakshwealth-api** — Lambdas + integrations
3. **jakshwealth-ui** — build + S3 sync

---

## Security

- Never commit AWS keys or passwords to git
- Rotate any credential shared in chat or logs
- Prefer IAM user keys over root account for automation
