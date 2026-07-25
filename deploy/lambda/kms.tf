locals {
  current_role_arn = var.role == null ? aws_iam_role.role_for_lambda[0].arn : var.role
}

resource "aws_kms_alias" "key_alias" {
  name          = "alias/${var.function_name}_${var.environment}_key"
  target_key_id = aws_kms_key.lambda_key.key_id
}

resource "aws_kms_key" "lambda_key" {
  description         = "KMS key for ${var.function_name} Lambda environment variables"
  is_enabled          = true
  enable_key_rotation = true
  tags                = var.tags
  policy              = <<EOF
{
    "Id": "key-consolepolicy",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "EnableIAMUserPermissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "AllowUseOfTheKey",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "${local.current_role_arn}"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
