variable "aws_region" {
  type        = string
  description = "Region for the parallel stack. Matches the live desk region."
  default     = "ap-south-2"
}

variable "aws_profile" {
  type        = string
  description = "Local AWS CLI profile. Matches bootstrap/terraform/vars.dev.tfvars."
  default     = "jakshwealth"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR for the parallel VPC. Distinct from bootstrap vpc_cidr 10.0.0.0/16."
  default     = "10.42.0.0/16"

  validation {
    condition     = var.vpc_cidr != "10.0.0.0/16"
    error_message = "The parallel VPC must not use the bootstrap VPC CIDR 10.0.0.0/16."
  }
}

variable "instance_type" {
  type        = string
  description = "Instance size for a network-bound daily candle scan."
  default     = "t3.small"
}

variable "allowed_cidr" {
  type        = string
  description = "IPv4 CIDR allowed to reach the load balancer on TCP 80."
  default     = "117.232.181.186/32"

  validation {
    condition     = can(cidrnetmask(var.allowed_cidr)) && var.allowed_cidr != "0.0.0.0/0"
    error_message = "allowed_cidr must be a specific IPv4 CIDR and must not be 0.0.0.0/0."
  }
}

variable "asg_min_size" {
  type        = number
  description = "Minimum scan instances. The group scales back to this when CPU is below the target."
  default     = 1
}

variable "asg_max_size" {
  type        = number
  description = "Maximum scan instances while CPU stays at or above the target."
  default     = 3

  validation {
    condition     = var.asg_max_size >= var.asg_min_size && var.asg_min_size >= 1
    error_message = "asg_max_size must be at least asg_min_size, and asg_min_size must be at least 1."
  }
}

variable "cpu_target_percent" {
  type        = number
  description = "Average CPU target. The group scales out above this and scales in below it."
  default     = 80

  validation {
    condition     = var.cpu_target_percent > 0 && var.cpu_target_percent <= 100
    error_message = "cpu_target_percent must be between 1 and 100."
  }
}

variable "root_volume_gb" {
  type        = number
  description = "Encrypted gp3 root volume size in GiB."
  default     = 20
}
