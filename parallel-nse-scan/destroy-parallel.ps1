$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$versions = Get-Content -Raw -Path (Join-Path $PSScriptRoot "versions.tf")
if ($versions -notmatch 'backend\s+"local"' -or $versions -notmatch 'parallel-test\.tfstate') {
    throw "Refusing to destroy: this directory is not the local parallel-test state."
}
if ($versions -match 'jakshwealth-infra-dev' -or $versions -match 'terraform-state-lock') {
    throw "Refusing to destroy: production backend settings are present."
}

$statePath = Join-Path $PSScriptRoot "parallel-test.tfstate"
if (-not (Test-Path $statePath)) {
    throw "Refusing to destroy: parallel-test.tfstate is not in this directory."
}

$state = Get-Content -Raw -Path $statePath
$forbidden = @("jakshwealth-infra-dev", "jw_kite", "terraform-state-lock", "aws_lambda_function", "aws_db_instance", "aws_cloudfront_distribution")
foreach ($token in $forbidden) {
    if ($state.Contains($token)) {
        throw "Refusing to destroy: state contains production marker '$token'."
    }
}
if ($state -notmatch "Parallel-Test") {
    throw "Refusing to destroy: state has no Parallel-Test resources."
}

terraform destroy -input=false @args
