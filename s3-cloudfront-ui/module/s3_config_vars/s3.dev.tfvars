deploy_env               = "dev"
aws_region               = "ap-south-2"
enable_custom_domain     = false
ui_bucket_name_override  = "jakshwealth.com"
use_s3_website_origin    = true
price_class              = "PriceClass_All"

cloudfront_origin_id_override      = "jakshwealth.com.s3.ap-south-2.amazonaws.com-msamlbk7qcn"
cloudfront_cache_policy_id         = "658327ea-f89d-4fab-a63d-7e88639e58f6"
cloudfront_web_acl_id              = "arn:aws:wafv2:us-east-1:305068201745:global/webacl/CreatedByCloudFront-0e6bb9c3/500188f9-9b8e-4b60-adba-b62621df87ee"
cloudfront_viewer_protocol_policy  = "allow-all"

ui_website_resources = ["arn:aws:s3:::jakshwealth.com", "arn:aws:s3:::jakshwealth.com/*"]
ui_website_users     = ["arn:aws:iam::305068201745:user/sachindad"]
owner_canonical_id       = "3f3b2c09588856bc6929e0bf63fc732ad3e434ecf6ee976d1a514bbc000d05fa"

project_tags = {
  Project     = "jakshwealth"
  Environment = "dev"
  Owner       = "jakshu2024@gmail.com"
}
