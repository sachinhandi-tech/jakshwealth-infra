variable "deploy_env" {
  type        = string
  description = "dev, test, or prod"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "jakshwealth"
}

variable "create_lock_table" {
  type    = bool
  default = true
}

variable "lock_table_name" {
  type    = string
  default = "terraform-state-lock"
}

variable "create_vpc" {
  type        = bool
  description = "Create jakshwealth-vpc and subnets (only needed if Lambdas run inside a VPC)"
  default     = false
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
