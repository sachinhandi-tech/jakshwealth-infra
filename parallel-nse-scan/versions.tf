terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # This root has its own local state. It never reads the production S3 backend.
  backend "local" {
    path = "parallel-test.tfstate"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
