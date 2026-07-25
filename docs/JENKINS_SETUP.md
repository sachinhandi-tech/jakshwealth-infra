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

Run on the EC2 host **as ec2-user** (once):

```bash
cd /tmp
curl -fsSL -O https://raw.githubusercontent.com/sachinhandi-tech/jakshwealth-infra/main/scripts/install-jenkins-prerequisites.sh
chmod +x install-jenkins-prerequisites.sh
./install-jenkins-prerequisites.sh
```

Or install manually:

```bash
# Terraform >= 1.6.0 (ap-south-2 S3 backend; install script defaults to 1.6.6)
curl -fsSL https://releases.hashicorp.com/terraform/1.6.6/terraform_1.6.6_linux_amd64.zip -o /tmp/terraform.zip
sudo unzip -o /tmp/terraform.zip -d /usr/local/bin
sudo chmod +x /usr/local/bin/terraform
terraform version

# Node.js 20+ (jakshwealth-ui Angular build)
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs   # Amazon Linux 2023
# sudo yum install -y nodejs  # Amazon Linux 2
node --version
npm --version

# AWS CLI (if missing)
sudo dnf install -y awscli   # Amazon Linux 2023
# sudo yum install -y awscli  # Amazon Linux 2
```

Verify **as jenkins**:

```bash
sudo -u jenkins terraform version
sudo -u jenkins aws sts get-caller-identity --profile jakshwealth
```

Also needed for other pipelines:

- Python 3 (jakshwealth-api)
- Node.js 20+ / npm (jakshwealth-ui)
- git

---

## 5. Deploy order

1. **jakshwealth-infra** — `TERRAFORM_ACTION=apply`
2. **jakshwealth-api** — `TERRAFORM_ACTION=apply`
3. **jakshwealth-ui**
