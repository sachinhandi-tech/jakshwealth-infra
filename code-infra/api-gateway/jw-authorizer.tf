locals {
  jw_authorizer_lambda_name = var.jw_authorizer_lambda_name != "" ? var.jw_authorizer_lambda_name : "jw_authorization_${var.environment}"
  jw_authorizer_invoke_arn  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.jw_authorizer_lambda_name}/invocations"
}

resource "aws_iam_role" "jwapi_invocation_role" {
  name = "jwapi_invocation_rle"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "jwapi_invocation_policy" {
  depends_on = [aws_iam_role.jwapi_invocation_role]
  name       = "jwapi_invocation_plicy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": [
                   "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:${local.jw_authorizer_lambda_name}"
                  ]
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "jwapi_invocation_attachment" {
  role       = aws_iam_role.jwapi_invocation_role.name
  policy_arn = aws_iam_policy.jwapi_invocation_policy.arn
}

resource "aws_api_gateway_authorizer" "jw_authorization" {
  depends_on                       = [aws_api_gateway_rest_api.main_jw_api, aws_iam_role.jwapi_invocation_role]
  name                             = "jw_authorization"
  rest_api_id                      = aws_api_gateway_rest_api.main_jw_api.id
  authorizer_uri                   = local.jw_authorizer_invoke_arn
  authorizer_credentials           = aws_iam_role.jwapi_invocation_role.arn
  type                             = "TOKEN"
  identity_source                  = "method.request.header.authorization"
  authorizer_result_ttl_in_seconds = 0
}
