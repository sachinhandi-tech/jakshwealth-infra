terraform {
  backend "s3" {}
}

data "aws_route53_zone" "zone" {
  count        = var.enable_custom_domain ? 1 : 0
  name         = var.domain_name
  private_zone = true
}

module "jwAPIGatewayArchitecture" {
  source                = "./../../api-gateway"
  project_tags          = var.project_tags
  environment           = var.environment
  enable_custom_domain  = var.enable_custom_domain
  certificate_arn_api   = var.certificate_arn_api
  hosted_zone_id        = var.enable_custom_domain ? data.aws_route53_zone.zone[0].id : ""
  api_domain_suffix     = var.api_domain_suffix
}
