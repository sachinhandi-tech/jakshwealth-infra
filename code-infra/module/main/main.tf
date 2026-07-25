terraform {
  backend "s3" {}
}

data "aws_route53_zone" "zone" {
  name         = var.domain_name
  private_zone = true
}

module "jwAPIGatewayArchitecture" {
  source              = "./../../api-gateway"
  project_tags        = var.project_tags
  environment         = var.environment
  certificate_arn_api = var.certificate_arn_api
  hosted_zone_id      = data.aws_route53_zone.zone.id
  api_domain_suffix   = var.api_domain_suffix
}
