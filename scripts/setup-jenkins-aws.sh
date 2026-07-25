# Run once on the Jenkins server as the jenkins user (personal setup).
# Console password does NOT work — use IAM access keys from user sachindad.

set -euo pipefail

PROFILE="${1:-jakshwealth}"
REGION="${2:-us-east-1}"

echo "Configure AWS CLI profile [${PROFILE}] for user: $(whoami)"
echo "Create access keys: IAM → sachindad → Security credentials → Create access key"
echo ""

aws configure --profile "${PROFILE}"
aws sts get-caller-identity --profile "${PROFILE}"

echo ""
echo "Profile ${PROFILE} is ready. Jenkins pipelines use aws_profile=${PROFILE} in .cicd/build_props/*.properties"
