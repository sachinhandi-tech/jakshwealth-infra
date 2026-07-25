resource "aws_cloudfront_origin_access_identity" "jakshwealth-ui-OAI" {
  comment = "Origin Access Identity for HPP Self-Service Analytics UI bucket"
}

resource "aws_cloudfront_distribution" "jakshwealth-ui" {
  depends_on = [
    aws_s3_bucket.jakshwealth-ui-website,
    aws_s3_bucket_ownership_controls.jakshwealth-ui-website-ownership-controls,
    aws_s3_bucket_acl.jakshwealth-ui-website-acl,
  ]

  origin {
    domain_name = "${aws_s3_bucket.jakshwealth-ui-website.id}.s3.amazonaws.com"
    origin_id   = "S3-${aws_s3_bucket.jakshwealth-ui-website.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.jakshwealth-ui-OAI.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = var.cf-ipv6
  default_root_object = "index.html"
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.jakshwealth-ui-website.bucket_domain_name
    prefix          = "logs"
  }
  aliases = var.enable_custom_domain ? ["ssa.${local.domain_name}"] : []
  custom_error_response {
    error_caching_min_ttl = "300"
    error_code            = "404"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.jakshwealth-ui-website.id}"


    forwarded_values {
      query_string = false

      cookies {
        forward = var.cf_cookies
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  price_class = var.price_class
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.enable_custom_domain ? [1] : []
    content {
      acm_certificate_arn      = data.aws_acm_certificate.hpp_cert[0].arn
      ssl_support_method       = "sni-only"
      minimum_protocol_version = var.minimum_protocol_version
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.enable_custom_domain ? [] : [1]
    content {
      cloudfront_default_certificate = true
    }
  }
  # Assigning the waf_channel tag takes care of the web_acl
#  web_acl_id = data.aws_wafv2_web_acl.cigna_internal_only.arn

  tags = merge(
    var.cigna_tags,
    var.waf_tags,
    {
      Purpose   = "Cloudfront for HPP Self-Service Analytics UI"
      AssetName = "HPP JakshWealth UI Cloudfront"
    }
  )
}
