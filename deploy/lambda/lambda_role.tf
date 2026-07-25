resource "aws_iam_role" "role_for_lambda" {
  count = var.role == null ? 1 : 0
  name = "HPP_${var.function_name}_${var.environment}"
  force_detach_policies = true
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "IAMAssumedRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = var.tags
}

resource "aws_iam_instance_profile" "lambda_PROFILE" {
  count = var.role == null ? 1 : 0
  name = "HPP_${var.function_name}_${var.environment}"
  role = aws_iam_role.role_for_lambda[count.index].name
}

resource "aws_iam_role_policy_attachment" "lambda_write_ACCESS" {
  count = var.role == null ? 1 : 0
  role = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = aws_iam_policy.lambda_write_access_POLICY[count.index].arn
}
resource "aws_iam_policy" "lambda_write_access_POLICY" {
  count = var.role == null ? 1 : 0
  name = "HPP_${upper(var.function_name)}_${var.environment}_LAMBDA_WRITE_ACCESS_PLCY"
  policy = file("${path.module}/lambda_role_policy.json")
}
resource "aws_iam_role_policy_attachment" "kms_s3_decrypt" {
  count = var.role == null ? 1 : 0
  role = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/cigna-us-da-hpp-artifacts-${var.environment}"
}

locals{
  trim_env = trimprefix(var.environment,"pre")
}

resource "aws_iam_role_policy_attachment" "s3_bucket_download" {
  count = var.role == null ? 1 : 0
  
  role = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/cigna-us-da-hpp-upload-download-${local.trim_env}"
}

resource "aws_iam_policy" "lambda_sqs_sfn_access_POLICY" {
  count = contains(regexall("[a-zA-Z\\s]*sqs", var.function_name), "sqs") ? 1 : 0
  name = "${upper(var.function_name)}_${var.environment}_LAMBDA_SQS_SFN_ACCESS_POLICY"
  policy = file("${path.module}/lambda_trigger_sfn_policy.json")
}
resource "aws_iam_role_policy_attachment" "lambda_sqs_ACCESS" {
  count = contains(regexall("[a-zA-Z\\s]*sqs", var.function_name), "sqs") ? 1 : 0
  role = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = aws_iam_policy.lambda_sqs_sfn_access_POLICY[count.index].arn
}
resource "aws_iam_policy" "lambda_sqs_for_appeal_POLICY" {
  count = contains(regexall("[a-zA-Z\\s]*appeal", var.function_name), "appeal") ? 1 : 0
  name = "${upper(var.function_name)}_${var.environment}_LAMBDA_SQS_FOR_APPEAL_POLICY"
  policy = file("${path.module}/lambda_trigger_sfn_policy.json")
}
resource "aws_iam_role_policy_attachment" "lambda_sqs_for_appeal_ACCESS" {
  count = contains(regexall("[a-zA-Z\\s]*appeal", var.function_name), "appeal") ? 1 : 0
  role = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = aws_iam_policy.lambda_sqs_for_appeal_POLICY[count.index].arn
}
resource "aws_iam_policy" "lambda_athena_history_POLICY" {
  count = contains(regexall("[a-zA-Z\\s]*history", var.function_name), "history") ? 1 : 0
  name = "${upper(var.function_name)}_${var.environment}_LAMBDA_ATHENA_HISTORY_POLICY"
  policy = file("${path.module}/lambda_athena_history_policy.json")
}
resource "aws_iam_role_policy_attachment" "lambda_athena_history_ACCESS" {
  count = contains(regexall("[a-zA-Z\\s]*history", var.function_name), "history") ? 1 : 0
  role = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = aws_iam_policy.lambda_athena_history_POLICY[count.index].arn
}
resource "aws_iam_policy" "glue_POLICY" {
  count = contains(regexall("[a-zA-Z\\s]*rx", var.function_name), "rx") ? 1 : 0
  name = "${upper(var.function_name)}_${var.environment}_GLUE_POLICY"
  policy = file("${path.module}/lambda_glue_policy.json")
}
resource "aws_iam_role_policy_attachment" "glue_ACCESS" {
  count = contains(regexall("[a-zA-Z\\s]*rx", var.function_name), "rx") ? 1 : 0
  role = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = aws_iam_policy.glue_POLICY[count.index].arn
}

resource "aws_iam_policy" "lambda_monthly_transparency_sfn_POLICY" {
  count = contains(regexall("[a-zA-Z\\s]*monthly_transparency", var.function_name), "monthly_transparency") ? 1 : 0
  name  = "${upper(var.function_name)}_${var.environment}_MONTHLY_TRANSPARENCY_SFN_POLICY"
  policy = file("${path.module}/lambda_monthly_transparency_sfn_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_monthly_transparency_sfn_ACCESS" {
  count      = contains(regexall("[a-zA-Z\\s]*monthly_transparency", var.function_name), "monthly_transparency") ? 1 : 0
  role       = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = aws_iam_policy.lambda_monthly_transparency_sfn_POLICY[count.index].arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.role == null ? 1 : 0
  role = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
