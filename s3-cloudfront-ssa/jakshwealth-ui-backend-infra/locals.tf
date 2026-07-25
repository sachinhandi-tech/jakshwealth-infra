locals {
    domain_name            = lookup(var.domain_name, var.deploy_env, "jakshwealth-dev.example.com")
    artifacts_bucket       = lookup(var.artifacts_bucket, var.deploy_env, "jakshwealth-artifacts-dev")
    hpp_infra_state_bucket = lookup(var.infra_state_bucket, var.deploy_env, "jakshwealth-infra-dev")
    alert_funnel_arn       = lookup(var.alert_funnel_arn, var.deploy_env, "")
    ssa_ui_bucket_name     = "jakshwealth-ui-${var.deploy_env}"
}
