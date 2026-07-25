terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

data "aws_caller_identity" "current" {}

locals {
  region_bucket_suffix = lookup({
    "ap-south-2" = "aps2"
    "us-east-1"  = "use1"
  }, var.aws_region, replace(var.aws_region, "-", ""))

  buckets = {
    infra     = "jakshwealth-infra-${var.deploy_env}-${local.region_bucket_suffix}"
    artifacts = "jakshwealth-artifacts-${var.deploy_env}-${local.region_bucket_suffix}"
    logs      = "jakshwealth-logs-${var.deploy_env}-${local.region_bucket_suffix}"
  }
  tags = {
    Project     = "jakshwealth"
    Environment = var.deploy_env
    ManagedBy   = "terraform-bootstrap"
  }
}

resource "aws_s3_bucket" "foundation" {
  for_each = local.buckets
  bucket   = each.value
  tags     = merge(local.tags, { Name = each.value, Purpose = each.key })
}

resource "aws_s3_bucket_versioning" "foundation" {
  for_each = aws_s3_bucket.foundation
  bucket   = each.value.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "foundation" {
  for_each = aws_s3_bucket.foundation
  bucket   = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "foundation" {
  for_each = aws_s3_bucket.foundation
  bucket   = each.value.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  count          = var.create_lock_table ? 1 : 0
  name           = var.lock_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}
