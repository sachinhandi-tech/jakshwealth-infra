data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_acm_certificate" "hpp_cert" {
  count    = var.enable_custom_domain ? 1 : 0
  domain   = local.domain_name
  statuses = ["ISSUED"]
}
