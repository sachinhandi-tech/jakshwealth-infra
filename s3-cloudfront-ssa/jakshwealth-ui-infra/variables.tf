variable "artifacts_bucket" {
  type    = map
  default = {
    dev  = "jakshwealth-artifacts-dev"
    test = "jakshwealth-artifacts-test"
    prod = "jakshwealth-artifacts-prod"
  }
}

variable "infra_state_bucket" {
  type    = map
  default = {
    dev  = "jakshwealth-infra-dev"
    test = "jakshwealth-infra-test"
    prod = "jakshwealth-infra-prod"
  }
}

variable "logs_bucket" {
  type    = map
  default = {
    dev  = "jakshwealth-logs-dev"
    test = "jakshwealth-logs-test"
    prod = "jakshwealth-logs-prod"
  }
}

variable "enable_custom_domain" {
  type        = bool
  description = "Use ACM cert + custom DNS alias (requires Route53 + certificate in AWS)"
  default     = false
}


variable "deploy_env" {
  default = ""
}


variable "domain_name" {
  type    = map
  default = {
    dev  = "jakshwealth-dev.example.com"
    test = "jakshwealth-test.example.com"
    prod = "jakshwealth-prod.example.com"
  }
}

/*
S3 Bucket variables for HPP Self-Service Analytics UI website
*/

variable "ssa_ui_website_resources" {
  type = list(string)
}

variable "ssa_ui_website_users" {
  type = list(string)
}

/*
Cloudfront Variables
*/

variable "minimum_protocol_version" {
  type        = string
  description = "Cloudfront TLS minimum protocol version"
  default     = "TLSv1.2_2021"
}

variable "cf_cookies" {
  default = "none"
}

variable "cf-ipv6" {
  default = true
}

variable "alert_funnel_arn" {
  type    = map
  default = {
    dev  = "arn:aws:sns:ap-south-2:929468956630:cloudwatch-alarm-funnel"
    test = "arn:aws:sns:ap-south-2:929468956630:cloudwatch-alarm-funnel"
    prod = "arn:aws:sns:ap-south-2:746770431074:cloudwatch-alarm-funnel"
  }
}

variable "price_class" {
  default = "PriceClass_100"
}

variable "cigna_tags" {
  description = "Maps of tags required for AWS resource"
  type        = map
}

variable "waf_tags" {
  description = "API Gateway tags required for AWS resource"
  type        = map
  default     = {
    waf_channel = "glo_internal_v2"
  }
}

# canonical_id for jakshwealth-ui website

variable "owner_canonical_id" {
  type        = string
  description = "canonical for s3"
}

variable "grantee_canonical_id" {
  type        = string
  description = "canonical for s3"
  default     = "c4c1ede66af53448b93c283ce9448c4ba468c9432aa01d700d3878632f77d2d0"
}
