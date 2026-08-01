terraform {
  backend "s3" {}
}

module "jakshwealth-ui-infra" {
  source                          = "../jakshwealth-ui-infra"
  deploy_env                      = var.deploy_env
  enable_custom_domain            = var.enable_custom_domain
  aws_region                      = var.aws_region
  ui_bucket_name_override         = var.ui_bucket_name_override
  use_s3_website_origin           = var.use_s3_website_origin
  cloudfront_origin_id_override   = var.cloudfront_origin_id_override
  cloudfront_cache_policy_id      = var.cloudfront_cache_policy_id
  cloudfront_web_acl_id           = var.cloudfront_web_acl_id
  cloudfront_viewer_protocol_policy = var.cloudfront_viewer_protocol_policy
  price_class                     = var.price_class
  ui_website_resources            = var.ui_website_resources
  ui_website_users                = var.ui_website_users
  owner_canonical_id              = var.owner_canonical_id
  project_tags                    = var.project_tags
}

module "jakshwealth-ui-backend-infra" {
  count              = var.enable_custom_domain ? 1 : 0
  source             = "../jakshwealth-ui-backend-infra"
  deploy_env         = var.deploy_env
  enable_custom_domain = var.enable_custom_domain
  cf-domain_name     = module.jakshwealth-ui-infra.cf_endpoint
  cf-hostedzone      = module.jakshwealth-ui-infra.cf_hosted_zone_id
  project_tags         = var.project_tags
}
