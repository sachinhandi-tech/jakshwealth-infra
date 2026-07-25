terraform {
  backend "s3" {}
}

module "jakshwealth-ui-infra" {
    source = "../jakshwealth-ui-infra"
    deploy_env = var.deploy_env
    ssa_ui_website_resources = var.ssa_ui_website_resources
    ssa_ui_website_users = var.ssa_ui_website_users
    owner_canonical_id = var.owner_canonical_id
    cigna_tags = var.cigna_tags
}

module "jakshwealth-ui-backend-infra" {
    source = "../jakshwealth-ui-backend-infra"
    deploy_env = var.deploy_env
    cf-domain_name = module.jakshwealth-ui-infra.hpp-cf-endpoint
    cf-hostedzone = module.jakshwealth-ui-infra.hpp-cf-hostedzone
    cigna_tags = var.cigna_tags
}
