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

variable "deletion_protection" {
  type        = bool
  default     = true
  description = "Keep the database from being deleted. The destroy job turns this off before it deletes the instance."
}

variable "skip_final_snapshot" {
  type        = bool
  default     = false
  description = "Skip the final snapshot. The destroy job sets this so no snapshot is left behind."
}

variable "secret_recovery_window_in_days" {
  type        = number
  default     = 30
  description = "Days Secrets Manager keeps a deleted secret. The destroy job sets 0 so the name can be created again."
}
