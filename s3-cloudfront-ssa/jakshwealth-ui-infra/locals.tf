locals {
    region_bucket_suffix = lookup({
      "ap-south-2" = "aps2"
      "us-east-1"  = "use1"
    }, var.aws_region, replace(var.aws_region, "-", ""))

    artifacts_bucket       = lookup(var.artifacts_bucket, var.deploy_env, "jakshwealth-artifacts-${var.deploy_env}-${local.region_bucket_suffix}")
    logs_bucket            = lookup(var.logs_bucket, var.deploy_env, "jakshwealth-logs-${var.deploy_env}-${local.region_bucket_suffix}")
    hpp_infra_state_bucket = lookup(var.infra_state_bucket, var.deploy_env, "jakshwealth-infra-${var.deploy_env}-${local.region_bucket_suffix}")
    domain_name            = lookup(var.domain_name, var.deploy_env, "jakshwealth-dev.example.com")
    alert_funnel_arn       = lookup(var.alert_funnel_arn, var.deploy_env, "")
    ssa_ui_bucket_name     = "jakshwealth-ui-${var.deploy_env}-${local.region_bucket_suffix}"
}
