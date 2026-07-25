data "aws_vpc" "golden" { 
  filter {
    name   = "tag:Name"
    values = ["hpp-cigna-golden-vpc"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_acm_certificate" "hpp-cert" {
  domain   = local.domain_name
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "zone" {
  name         = local.domain_name
  private_zone = true
}

data "aws_acm_certificate" "hpp-logger-cert" {
  domain   = local.domain_name
  statuses = ["ISSUED"]
}
