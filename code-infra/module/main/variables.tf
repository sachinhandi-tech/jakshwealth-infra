variable "provider_profile" {
  default = "default"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "environment" {
  description = "Deployment environment (dev, test, prod)"
  default     = "dev"
}

variable "enable_custom_domain" {
  type    = bool
  default = false
}

variable "certificate_arn_api" {
  description = "ACM certificate ARN for the API custom domain (when enable_custom_domain is true)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Private Route53 hosted zone name (e.g. jakshwealth-dev.example.com)"
  type        = string
}

variable "api_domain_suffix" {
  description = "DNS suffix for the API Gateway custom domain"
  type        = string
}

variable "project_tags" {
  description = "Tags applied to JakshWealth infrastructure resources"
  type        = map(string)
  default = {
    project      = "JakshWealth"
    ResourceName = "jakshwealth"
  }
}
