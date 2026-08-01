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

variable "ui_bucket_name_override" {
  type        = string
  description = "Override UI S3 bucket name (e.g. jakshwealth.com)."
  default     = ""
}

variable "use_s3_website_origin" {
  type        = bool
  description = "Use the S3 static website endpoint as the CloudFront custom origin."
  default     = false
}

variable "deploy_env" {
  default = ""
}

variable "aws_region" {
  type    = string
  default = "ap-south-2"
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
S3 Bucket variables for JakshWealth UI website
*/

variable "ui_website_resources" {
  type = list(string)
}

variable "ui_website_users" {
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

variable "project_tags" {
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
  description = "S3 bucket owner canonical user ID for this AWS account."
}
