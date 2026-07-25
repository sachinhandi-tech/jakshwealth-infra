# Jenkins setup (JakshWealth)

## 1. GitHub (private repos)

**Manage Jenkins → Credentials → Add**

| Field | Value |
|-------|--------|
| Kind | Username with password |
| Username | `sachinhandi-tech` |
| Password | GitHub Personal Access Token |
| ID | `jakshwealth-ui` (or any ID — select it in Branch Sources) |

---

## 2. AWS (default — profile on Jenkins server)

Pipelines use **`AWS_PROFILE=jakshwealth`** from `.cicd/build_props/*.properties`.
`aws_credentials_id` is **empty** by default (no Jenkins AWS credential required).

On the Jenkins server, run **as the `jenkins` user**:

```bash
sudo -u jenkins bash
./scripts/setup-jenkins-aws.sh jakshwealth
# Or: aws configure --profile jakshwealth
aws sts get-caller-identity --profile jakshwealth
```

Use **IAM access keys** for user `sachindad` (console password does not work for CLI/Terraform).

---

## 3. AWS (optional — Jenkins credential)

To store keys in Jenkins instead of `~/.aws/credentials`:

1. **Manage Jenkins → Credentials → Add → AWS Credentials**
2. ID: `jakshwealth-aws`
3. Set in `.cicd/build_props/*.properties`:
   ```
   aws_credentials_id=jakshwealth-aws
   ```

---

## 4. Tools on Jenkins server

- Terraform 1.1.9+
- AWS CLI v2
- Python 3 (API pipeline)
- Node.js 20+ / npm (UI pipeline)
- git

---

## 5. Deploy order

1. **jakshwealth-infra** — `TERRAFORM_ACTION=apply`
2. **jakshwealth-api** — `TERRAFORM_ACTION=apply`
3. **jakshwealth-ui**
