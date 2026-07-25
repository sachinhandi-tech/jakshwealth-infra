data "aws_caller_identity" "current" {}

locals{
  kms_environment = trimprefix(var.environment, "pre")
}

data "aws_kms_key" "ccd_managed_key" {
  key_id = "alias/cigna-us-da-hpp-artifacts-${local.kms_environment}"
}