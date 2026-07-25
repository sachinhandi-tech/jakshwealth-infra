locals {
    current_role_arn = var.role == null ? aws_iam_role.role_for_lambda[0].arn : var.role
}

resource "aws_kms_alias" "key_alias" {
  name          = "alias/${var.function_name}_${var.environment}_key"
  target_key_id = aws_kms_key.lambda_key.key_id
}

resource "aws_kms_key" "lambda_key" {
  description           = "This key can be used for password encryptions"
  is_enabled            = "true"
  enable_key_rotation   = "true"
  tags                  = var.tags
  policy = <<EOF
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
            "Sid": "AllowAccessForKeyAdministrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HPNCCDJENKINS"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowUseOfTheKey",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/GLUEETL",
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HPNCCDJENKINS",
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
        },
        {
            "Sid": "AllowAttachmentOfPersistentResources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/Enterprise/GLUEETL",
                    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/HPNCCDJENKINS",
                    "${local.current_role_arn}"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
    ]
}
EOF
}