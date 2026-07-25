deploy_env           = "dev"
enable_custom_domain = false

ssa_ui_website_resources = ["arn:aws:s3:::jakshwealth-ui-dev", "arn:aws:s3:::jakshwealth-ui-dev/*"]
ssa_ui_website_users     = ["arn:aws:iam::305068201745:user/sachindad"]
owner_canonical_id       = "3f3b2c09588856bc6929e0bf63fc732ad3e434ecf6ee976d1a514bbc000d05fa"

cigna_tags = {
  Project     = "jakshwealth"
  Environment = "dev"
  Owner       = "jakshu2024@gmail.com"
}
