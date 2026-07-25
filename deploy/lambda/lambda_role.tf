resource "aws_iam_role" "role_for_lambda" {
  count                 = var.role == null ? 1 : 0
  name                  = "JW_${var.function_name}_${var.environment}"
  force_detach_policies = true
  assume_role_policy    = <<EOF
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

resource "aws_iam_policy" "lambda_write_access_POLICY" {
  count  = var.role == null ? 1 : 0
  name   = "JW_${upper(var.function_name)}_${var.environment}_LAMBDA_WRITE_ACCESS"
  policy = file("${path.module}/lambda_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "lambda_write_ACCESS" {
  count      = var.role == null ? 1 : 0
  role       = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = aws_iam_policy.lambda_write_access_POLICY[count.index].arn
}

resource "aws_iam_policy" "artifacts_s3_access" {
  count = var.role == null ? 1 : 0
  name  = "JW_${upper(var.function_name)}_${var.environment}_ARTIFACTS_S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::jakshwealth-artifacts-${var.environment}",
        "arn:aws:s3:::jakshwealth-artifacts-${var.environment}/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "artifacts_s3" {
  count      = var.role == null ? 1 : 0
  role       = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = aws_iam_policy.artifacts_s3_access[count.index].arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = var.role == null && length(var.subnet_ids) > 0 ? 1 : 0
  role       = aws_iam_role.role_for_lambda[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}
