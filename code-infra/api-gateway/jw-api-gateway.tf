resource "aws_api_gateway_rest_api" "main_jw_api" {
  name                         = var.jw_api_name
  description                  = "REST API for JakshWealth"
  disable_execute_api_endpoint = var.enable_custom_domain

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.project_tags, var.api_gw_tags)
}

resource "aws_api_gateway_resource" "jwapi_root" {
  path_part   = "{proxy+}"
  parent_id   = aws_api_gateway_rest_api.main_jw_api.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.main_jw_api.id
}

resource "aws_api_gateway_domain_name" "jwapi_gatewaydns" {
  count                    = var.enable_custom_domain ? 1 : 0
  domain_name              = "${var.route53name_jw_api}-g.${var.api_domain_suffix}"
  regional_certificate_arn = var.certificate_arn_api

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_gateway_response" "jw-api-gateway-default4xx" {
  rest_api_id         = aws_api_gateway_rest_api.main_jw_api.id
  response_type       = "DEFAULT_4XX"
  response_parameters = var.cors_response_params
  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }
}

resource "aws_api_gateway_gateway_response" "jw-api-gateway-default5xx" {
  rest_api_id         = aws_api_gateway_rest_api.main_jw_api.id
  response_type       = "DEFAULT_5XX"
  response_parameters = var.cors_response_params
  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }
}

resource "aws_api_gateway_method" "jw_options_method" {
  rest_api_id   = aws_api_gateway_rest_api.main_jw_api.id
  resource_id   = aws_api_gateway_resource.jwapi_root.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "jw_options_200" {
  rest_api_id = aws_api_gateway_rest_api.main_jw_api.id
  resource_id = aws_api_gateway_resource.jwapi_root.id
  http_method = aws_api_gateway_method.jw_options_method.http_method
  status_code = 200
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
  depends_on = [aws_api_gateway_method.jw_options_method]
}

resource "aws_api_gateway_integration" "jw_options_integration" {
  rest_api_id          = aws_api_gateway_rest_api.main_jw_api.id
  resource_id          = aws_api_gateway_resource.jwapi_root.id
  http_method          = aws_api_gateway_method.jw_options_method.http_method
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = <<EOF
{ "statusCode" : 200, "message": "I am healthy" }
EOF
  }
  depends_on = [aws_api_gateway_method.jw_options_method]
}

resource "aws_api_gateway_integration_response" "jw_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.main_jw_api.id
  resource_id = aws_api_gateway_resource.jwapi_root.id
  http_method = aws_api_gateway_method.jw_options_method.http_method
  status_code = aws_api_gateway_method_response.jw_options_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,authorizationToken,auth_code,refresh_token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,PATCH,HEAD,DELETE'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [
    aws_api_gateway_method_response.jw_options_200,
    aws_api_gateway_integration.jw_options_integration,
  ]
}
