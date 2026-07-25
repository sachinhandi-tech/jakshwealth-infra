resource "aws_cloudwatch_metric_alarm" "CF4xxCount" {
  alarm_name                = "HPP-SSA-UI-CF4xxCount"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "4xxErrorRate"
  namespace                 = "AWS/CloudFront"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "${var.deploy_env}|INFO|HPP|HPP JakshWealth UI Cloudfront 4xx Count"
  alarm_actions = [local.alert_funnel_arn]
  tags = var.cigna_tags
}

resource "aws_cloudwatch_metric_alarm" "CF5xxCount" {
  alarm_name                = "HPP-SSA-UI-CF5xxCount"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = "2"
  metric_name               = "5xxErrorRate"
  namespace                 = "AWS/CloudFront"
  period                    = "60"
  statistic                 = "Sum"
  threshold                 = "1"
  alarm_description         = "${var.deploy_env}|CRITICAL|HPP|HPP JakshWealth UI Cloudfront 5xx Count"
  alarm_actions = [local.alert_funnel_arn]
  tags = var.cigna_tags
}

resource "aws_cloudwatch_metric_alarm" "jakshwealth-ui-website_alarm_4xx" {
  
  alarm_name                = "jakshwealth-ui-${var.deploy_env}-400-errors"
  alarm_actions             = [local.alert_funnel_arn]
  alarm_description         = "${var.deploy_env}|INFO|HPP|jakshwealth-ui-${var.deploy_env}-400 errors threshold met"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  dimensions = {
    BucketName = local.ssa_ui_bucket_name
    FilterId = "EntireBucket"
  }
  evaluation_periods        = 4
  metric_name               = "4xxErrors"
  namespace                 = "AWS/S3"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 2
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  tags = merge(
      var.cigna_tags,
      {
        Purpose = "Alarm for HPP JakshWealth UI 4XX errors"
        AssetName = "HPP JakshWealth UI 4XX errors Alarm"
      } 
      )
}

resource "aws_cloudwatch_metric_alarm" "jakshwealth-ui-website_alarm_5xx" {
  
  alarm_name                = "jakshwealth-ui-${var.deploy_env}-500-errors"
  alarm_actions             = [local.alert_funnel_arn]
  alarm_description         = "${var.deploy_env}|CRITICAL|HPP|jakshwealth-ui-${var.deploy_env}-500 errors threshold met"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  dimensions = {
    BucketName = local.ssa_ui_bucket_name
    FilterId = "EntireBucket"
  }
  evaluation_periods        = 4
  metric_name               = "5xxErrors"
  namespace                 = "AWS/S3"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 2
  treat_missing_data        = "notBreaching"
  insufficient_data_actions = []
  tags = merge(
      var.cigna_tags,
      {
        Purpose = "Alarm for HPP JakshWealth UI 5XX errors"
        AssetName = "HPP JakshWealth UI 5XX errors Alarm"
      } 
      )
}

resource "aws_cloudwatch_metric_alarm" "S3latency" {
  alarm_name                = "HPP-SSA-UI-S3FirstByteLatency"
  comparison_operator       = "GreaterThanThreshold"
  dimensions = {
    BucketName = local.ssa_ui_bucket_name
    FilterId = "EntireBucket"
  }
  evaluation_periods        = 2
  metric_name               = "FirstByteLatency"
  namespace                 = "AWS/S3"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 1000
  alarm_description         = "${var.deploy_env}|WARN|HPP|jakshwealth-ui-${var.deploy_env} First Byte Latency"
  alarm_actions = [local.alert_funnel_arn]
  tags = merge(
      var.cigna_tags,
      {
        Purpose = "Alarm for HPP JakshWealth UI Latency"
        AssetName = "HPP JakshWealth UI Latency Alarm"
      } 
      )
}
