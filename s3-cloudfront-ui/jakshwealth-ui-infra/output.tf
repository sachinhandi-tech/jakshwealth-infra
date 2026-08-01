output "website_bucket_name" {
  value = aws_s3_bucket.jakshwealth-ui-website.id
}

output "cf_endpoint" {
  value = aws_cloudfront_distribution.jakshwealth-ui.domain_name
}

output "cf_hosted_zone_id" {
  value = aws_cloudfront_distribution.jakshwealth-ui.hosted_zone_id
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.jakshwealth-ui.id
}
