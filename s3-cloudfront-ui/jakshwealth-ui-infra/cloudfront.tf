resource "aws_cloudfront_origin_access_identity" "jakshwealth-ui-OAI" {
  count   = var.use_s3_website_origin ? 0 : 1
  comment = "Origin Access Identity for JakshWealth UI bucket"
}

resource "aws_cloudfront_distribution" "jakshwealth-ui" {
  depends_on = [
    aws_s3_bucket.jakshwealth-ui-website,
    aws_s3_bucket_ownership_controls.jakshwealth-ui-website-ownership-controls,
    aws_s3_bucket_acl.jakshwealth-ui-website-acl,
  ]

  origin {
    domain_name = var.use_s3_website_origin ? "${aws_s3_bucket.jakshwealth-ui-website.bucket}.s3-website.${var.aws_region}.amazonaws.com" : aws_s3_bucket.jakshwealth-ui-website.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.jakshwealth-ui-website.id}"

    dynamic "s3_origin_config" {
      for_each = var.use_s3_website_origin ? [] : [1]
      content {
        origin_access_identity = aws_cloudfront_origin_access_identity.jakshwealth-ui-OAI[0].cloudfront_access_identity_path
      }
    }

    dynamic "custom_origin_config" {
      for_each = var.use_s3_website_origin ? [1] : []
      content {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
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
  aliases = var.enable_custom_domain ? ["app.${local.domain_name}"] : []

  # S3 REST origins return 403 (not 404) for missing keys when using OAI.
  # Website origins return 404. Both must map to index.html for SPA deep links.
  custom_error_response {
    error_caching_min_ttl = "300"
    error_code            = "403"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

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
      acm_certificate_arn      = data.aws_acm_certificate.ui_cert[0].arn
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

  tags = merge(
    var.project_tags,
    var.waf_tags,
    {
      Purpose   = "Cloudfront for JakshWealth UI"
      AssetName = "JakshWealth UI Cloudfront"
    }
  )
}
