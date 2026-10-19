variable "aws_region" {
  type    = string
  default = "ap-south-2"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "kite_api_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Zerodha Kite app key. Stored in Secrets Manager; Terraform does not overwrite an existing secret value."
}

variable "kite_api_secret" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Zerodha Kite app secret. Stored in Secrets Manager; Terraform does not overwrite an existing secret value."
}
