data "aws_vpc" "golden" { 
  filter {
    name   = "tag:Name"
    values = ["hpp-cigna-golden-vpc"]
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_acm_certificate" "pmp-logger-cert" {
  domain   = local.domain_name
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "zone" {
  name         = local.domain_name
  private_zone = true
}

#data "aws_waf_web_acl" "cigna_internal_only" {
#  name = local.webacl_name
#}

#data "aws_wafv2_web_acl" "cigna_internal_only" {
#  name  = local.webacl_name
#  scope = "REGIONAL"
#}

data "aws_acm_certificate" "hpp-cert" {
  domain   = local.domain_name
  statuses = ["ISSUED"]
}

data "aws_s3_bucket" "logs" {
  bucket = local.logs_bucket
}
