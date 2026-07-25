terraform {
  backend "s3" {}
}

module "jakshwealth-ui-infra" {
  source                   = "../jakshwealth-ui-infra"
  deploy_env               = var.deploy_env
  enable_custom_domain     = var.enable_custom_domain
  aws_region               = var.aws_region
  ui_website_resources = var.ui_website_resources
  ui_website_users     = var.ui_website_users
  owner_canonical_id       = var.owner_canonical_id
  project_tags               = var.project_tags
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
