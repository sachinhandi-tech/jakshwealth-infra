resource "aws_lambda_function" "lambda" {
  depends_on = [
    aws_iam_role_policy_attachment.lambda_write_ACCESS,
    aws_iam_role_policy_attachment.artifacts_s3
  ]
  function_name                          = "${var.function_name}_${var.environment}"
  description                           = var.description
  role                                  = var.role == null ? aws_iam_role.role_for_lambda[0].arn : var.role
  s3_bucket                             = var.s3artifactbucket
  s3_key                                = var.s3artifactkey
  s3_object_version                     = var.s3objectversion
  handler                               = var.handler
  runtime                               = var.runtime
  timeout                               = var.timeout
  memory_size                           = var.memory_size
  reserved_concurrent_executions        = var.reserved_concurrent_executions
  layers                                = var.layers
  tags                                  = var.tags
  kms_key_arn                           = aws_kms_key.lambda_key.arn

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  ephemeral_storage {
    size = var.ephemeral_memory # Min 512 MB and the Max 10240 MB
  }

  environment {
    variables = merge({
      shortenvironment = var.environment
    }, var.environmental_variables)
  }
}

resource "aws_cloudwatch_metric_alarm" "sample_error_metrics" {
  count                     = var.alert_funnel_arn != "" ? 1 : 0
  alarm_name                = "${var.function_name}-${var.environment}-errors"
  namespace                 = "AWS/Lambda"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "1"
  threshold                 = "60"
  metric_name               = "Errors"
  period                    = "180"
  statistic                 = "Sum"
  alarm_actions             = [ var.alert_funnel_arn ]
  treat_missing_data        = "notBreaching"
  alarm_description         = "${var.environment} | CRITICAL | JakshWealth | Error while executing the ${var.function_name} lambda function (Threshold - Errors > 0 )"
  dimensions = {
    FunctionName = "${var.function_name}_${var.environment}"
  }

  tags                       = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda-throttling" {
  count               = var.alert_funnel_arn != "" ? 1 : 0
  alarm_name          = "${var.function_name}-${var.environment}-throttling"
  alarm_description   = "${var.environment} | WARN | JakshWealth | Throttled while executing the ${var.function_name} lambda function"
  alarm_actions       = [var.alert_funnel_arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/Lambda"
  metric_name         = "Throttles"
  statistic           = "Sum"
  period              = "300"
  threshold           = "20"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${var.function_name}_${var.environment}"
  }

  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda-duration" {
  count               = var.alert_funnel_arn != "" ? 1 : 0
  alarm_name          = "${var.function_name}-${var.environment}-duration"
  alarm_description   = "${var.environment} | INFO | JakshWealth | Execution time exceeding threshold (${var.alarm_duration} sec) for ${var.function_name} lambda function"
  alarm_actions       = [var.alert_funnel_arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  namespace           = "AWS/Lambda"
  metric_name         = "Duration"
  statistic           = "Maximum"
  period              = var.period
  threshold           = var.alarm_duration
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${var.function_name}_${var.environment}"
  }

  tags                = var.tags
}

/*
resource "aws_cloudwatch_log_group" "lambda-logs" {
    name = "/aws/lambda/${var.function_name}_${var.environment}"
}


resource "aws_cloudwatch_log_subscription_filter" "lambda-logs-sub" {
  count = var.enable_log_subscription ? 1 : 0
  
  name            = "/aws/lambda/${var.function_name}_${var.environment}_Accesslogs_Subscription"
  log_group_name  = "/aws/lambda/${var.function_name}"
  filter_pattern  = ""
  destination_arn = var.destination_arn
  distribution    = "ByLogStream"
  depends_on = [
    aws_cloudwatch_log_group.lambda-logs
  ]
}
*/

locals {
  # Normal queue for when new appeals are added
  ccd_appeal_queue_arn = format("arn:aws:sqs:us-east-1:%d:%s.fifo", data.aws_caller_identity.current.id, local.appeals_queue_name)
  # Queue for when we need to rerun appeals
  ccd_appeal_rerun_queue_arn = format("arn:aws:sqs:us-east-1:%d:%s.fifo", data.aws_caller_identity.current.id, local.appeals_rerun_name)
  appeals_queue_name = var.environment == "predev" ? "${var.appeals_sqs_queue_name}-predev" :  var.environment == "pretest" ? "${var.appeals_sqs_queue_name}-pretest" : var.environment == "preprod" ? "${var.appeals_sqs_queue_name}-preprod" : var.environment == "dev" ? "${var.appeals_sqs_queue_name}-dev": var.environment == "test" ? "${var.appeals_sqs_queue_name}-test": var.environment == "prod" ? "${var.appeals_sqs_queue_name}-prod":var.appeals_sqs_queue_name 
  appeals_rerun_name = var.environment == "predev" ? "${var.appeal_rerun_queue_name}-predev" :  var.environment == "pretest" ? "${var.appeal_rerun_queue_name}-pretest" : var.environment == "preprod" ? "${var.appeal_rerun_queue_name}-preprod" : var.appeal_rerun_queue_name
}

resource "aws_lambda_event_source_mapping" "ccd_appeals_sqs_mapping" {
  count = contains(regexall("[a-zA-Z\\s]*appeals-sqs", var.function_name), "appeals-sqs") ? 1 : 0
  event_source_arn = local.ccd_appeal_queue_arn
  function_name    = aws_lambda_function.lambda.arn
  batch_size = 1
}
//
//resource "aws_lambda_event_source_mapping" "ccd_appeal_rerun_sqs_mapping" {
//  count = contains(regexall("[a-zA-Z\\s]*rerun-sqs", var.function_name), "rerun-sqs") ? 1 : 0
//  event_source_arn = local.ccd_appeal_queue_arn
//  function_name    = aws_lambda_function.lambda.arn
//}

