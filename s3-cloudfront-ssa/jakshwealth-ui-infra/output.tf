output "website_bucket_name" {
  value = aws_s3_bucket.jakshwealth-ui-website.id
}

output "hpp-cf-endpoint" {
  value = aws_cloudfront_distribution.jakshwealth-ui.domain_name
}

output "hpp-cf-hostedzone" {
  value =aws_cloudfront_distribution.jakshwealth-ui.hosted_zone_id
}
