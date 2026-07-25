resource "aws_s3_bucket" "jakshwealth-ui-website" {
  bucket = local.ssa_ui_bucket_name

  force_destroy = true

  tags = merge(
    var.cigna_tags,
    var.waf_tags,
    {
      DataRetentionCode      = "7 Years"
      Environment            = var.deploy_env
      RegionalRestriction    = "us-east-1"
    }
  )
}

#Added Acl to test
resource "aws_s3_bucket_ownership_controls" "jakshwealth-ui-website-ownership-controls" {
bucket = aws_s3_bucket.jakshwealth-ui-website.id
rule {
  object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "jakshwealth-ui-website-acl" {
  depends_on = [aws_s3_bucket_ownership_controls.jakshwealth-ui-website-ownership-controls]

  bucket = aws_s3_bucket.jakshwealth-ui-website.id
  access_control_policy {
    grant {
      grantee {
        id   = var.grantee_canonical_id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }
    owner {
      id = var.owner_canonical_id
    }
  }
}

resource "aws_s3_bucket_policy" "hpp_ssa_ui_website_bucket_plcy" {
  bucket = aws_s3_bucket.jakshwealth-ui-website.id
  policy = templatefile("${path.module}/jakshwealth-ui-s3_policy.tpl", {
    key_users        = jsonencode(var.ssa_ui_website_users),
    bucket_resources = jsonencode(var.ssa_ui_website_resources),
    cloudfront_OAI   = jsonencode([aws_cloudfront_origin_access_identity.jakshwealth-ui-OAI.iam_arn])
  })

}

resource "aws_s3_bucket_versioning" "hpp_ssa_ui_website_bucket_versioning" {
  bucket = aws_s3_bucket.jakshwealth-ui-website.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_lifecycle_configuration" "hpp_ssa_ui_website_bucket_life_config" {
  bucket = aws_s3_bucket.jakshwealth-ui-website.id

  rule {
    id     = "intelligent_tiering"
    status = "Enabled"
    transition {
      days          = 365
      storage_class = "INTELLIGENT_TIERING"
    }
    noncurrent_version_transition {
      noncurrent_days = 365
      storage_class   = "INTELLIGENT_TIERING"
    }
  }
  rule {
    id     = "glacier"
    status = "Enabled"
    transition {
      days          = 2555
      storage_class = "GLACIER"
    }
    noncurrent_version_transition {
      noncurrent_days = 2555
      storage_class   = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "hpp_ssa_ui_website_bucket_enc_config" {
  bucket = aws_s3_bucket.jakshwealth-ui-website.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_metric" "jakshwealth-ui-website_metric" {
  depends_on = [aws_s3_bucket.jakshwealth-ui-website]
  bucket = local.ssa_ui_bucket_name
  name   = "EntireBucket"
}
