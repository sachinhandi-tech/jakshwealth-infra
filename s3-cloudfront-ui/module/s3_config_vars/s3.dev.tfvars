deploy_env               = "dev"
aws_region               = "ap-south-2"
enable_custom_domain     = false
ui_bucket_name_override  = "jakshwealth.com"
use_s3_website_origin    = true

ui_website_resources = ["arn:aws:s3:::jakshwealth.com", "arn:aws:s3:::jakshwealth.com/*"]
ui_website_users     = ["arn:aws:iam::305068201745:user/sachindad"]
owner_canonical_id       = "3f3b2c09588856bc6929e0bf63fc732ad3e434ecf6ee976d1a514bbc000d05fa"

project_tags = {
  Project     = "jakshwealth"
  Environment = "dev"
  Owner       = "jakshu2024@gmail.com"
}
