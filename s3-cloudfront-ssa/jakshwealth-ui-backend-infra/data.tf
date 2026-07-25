data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_route53_zone" "zone" {
  count        = var.enable_custom_domain ? 1 : 0
  name         = local.domain_name
  private_zone = true
}

data "aws_acm_certificate" "hpp_cert" {
  count    = var.enable_custom_domain ? 1 : 0
  domain   = local.domain_name
  statuses = ["ISSUED"]
}
