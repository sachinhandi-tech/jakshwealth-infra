variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-2"
}

variable "enable_custom_domain" {
  type        = bool
  description = "Enable Route53/ACM-backed custom domain (personal AWS: leave false)"
  default     = false
}

variable "deploy_env" {
  default = ""
}

variable "ui_website_resources" {
	type = list(string)
}

variable "ui_website_users" {
  type = list(string)
}


variable "project_tags" {
  type = map
}

variable "cf-domain_name" {
  default = ""
}

variable "cf-hostedzone" {
  default = ""
}

variable "owner_canonical_id" {
  type        = string
  description = "canonical for s3"
}
