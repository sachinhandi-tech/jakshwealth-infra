locals {
    artifacts_bucket = lookup(var.artifacts_bucket, var.deploy_env, "cigna-us-jakshwealth-artifacts-dev")
    logs_bucket = lookup(var.logs_bucket, var.deploy_env, "cigna-us-jakshwealth-logs-dev")
    hpp_infra_state_bucket = lookup(var.infra_state_bucket, var.deploy_env, "cigna-us-jakshwealth-infra-dev")
    domain_name = lookup(var.domain_name, var.deploy_env, "jakshwealth-dev.aws.cignacloud.com")
#    webacl_name = lookup(var.global_cf_web_acl, var.deploy_env, "")

    alert_funnel_arn = lookup(var.alert_funnel_arn, var.deploy_env, "")
    ssa_ui_bucket_name = "jakshwealth-ui-${var.deploy_env}"
}
