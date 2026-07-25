ssa_ui_website_resources = ["arn:aws:s3:::jakshwealth-ui-dev", "arn:aws:s3:::jakshwealth-ui-dev/*"]
# IAM user for S3/CloudFront deploy (create in IAM if not present)
ssa_ui_website_users     = ["arn:aws:iam::305068201745:user/sachindad"]
# From: aws s3api list-buckets --profile jakshwealth --query Owner.ID --output text
owner_canonical_id       = "3f3b2c09588856bc6929e0bf63fc732ad3e434ecf6ee976d1a514bbc000d05fa"

cigna_tags = {
  Project     = "jakshwealth"
  Environment = "dev"
  Owner       = "jakshu2024@gmail.com"
}
