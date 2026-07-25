#!/usr/bin/env bash
# Install Jenkins server prerequisites for JakshWealth pipelines (run as ec2-user with sudo).
set -euo pipefail

TF_VERSION="${TF_VERSION:-1.1.9}"

echo "Installing Terraform ${TF_VERSION} and checking AWS CLI..."

if ! command -v aws >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y awscli
  else
    sudo yum install -y awscli
  fi
fi

if ! command -v terraform >/dev/null 2>&1 || [[ "$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || terraform version | head -1)" != "${TF_VERSION}"* ]]; then
  TMP=$(mktemp -d)
  curl -fsSL "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" -o "${TMP}/terraform.zip"
  unzip -qo "${TMP}/terraform.zip" -d "${TMP}"
  sudo install -m 755 "${TMP}/terraform" /usr/local/bin/terraform
  rm -rf "${TMP}"
fi

echo ""
echo "Installed versions:"
aws --version
terraform version

echo ""
echo "Ensure jenkins user has AWS profile jakshwealth:"
echo "  sudo su - jenkins"
echo "  aws configure --profile jakshwealth"
echo "  aws sts get-caller-identity --profile jakshwealth"
