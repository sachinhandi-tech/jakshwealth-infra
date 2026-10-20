$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$backend = Get-Content -Raw -Path (Join-Path $PSScriptRoot "backend.dev.tfvars")
if ($backend -notmatch 'dev/parallel-nse-scan/terraform\.tfstate') {
    throw "Refusing to destroy: backend key is not dev/parallel-nse-scan/terraform.tfstate."
}
foreach ($token in @("dev/jakshwealth/terraform.tfstate", "dev/jakshwealth-postgres/terraform.tfstate")) {
    if ($backend.Contains($token)) {
        throw "Refusing to destroy: backend points at production state $token."
    }
}

terraform init -input=false -reconfigure -backend-config="backend.dev.tfvars"
$state = terraform state pull
foreach ($token in @("aws_lambda_function", "aws_db_instance", "aws_cloudfront_distribution", "jw_kite")) {
    if ($state.Contains($token)) {
        throw "Refusing to destroy: state contains production marker $token."
    }
}
if ($state -notmatch "Parallel-Test") {
    throw "Refusing to destroy: state has no Parallel-Test resources."
}

terraform destroy -input=false @args
