data "external" "jw_authorizer" {
  count   = var.authorization == "false" ? 0 : 1
  program = ["bash", "${path.module}/lookup_authorizer.sh"]
}

resource "aws_api_gateway_method" "request_method" {
  rest_api_id   = var.rest_api_id
  resource_id   = var.resource_id
  http_method   = var.method
  authorization = var.authorization == "false" ? "NONE" : "CUSTOM"
  authorizer_id = var.authorization == "false" ? "" : data.external.jw_authorizer[0].result.authorizer_id
  request_parameters = var.authorization == "false" ? {} : var.auth_request_param
}

resource "aws_api_gateway_integration" "request_method_integration" {
  rest_api_id             = var.rest_api_id
  resource_id             = var.resource_id
  http_method             = aws_api_gateway_method.request_method.http_method
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.lambda}/invocations"
  integration_http_method = "POST"
}

resource "aws_api_gateway_method_response" "response_method" {
  rest_api_id         = var.rest_api_id
  resource_id         = var.resource_id
  http_method         = aws_api_gateway_integration.request_method_integration.http_method
  status_code         = "200"
  response_parameters = var.response_parameters
  response_models     = var.response_models
}

resource "aws_api_gateway_integration_response" "response_method_integration" {
  rest_api_id = var.rest_api_id
  resource_id = var.resource_id
  http_method = aws_api_gateway_method_response.response_method.http_method
  status_code = aws_api_gateway_method_response.response_method.status_code

  response_templates = {
    "application/json" = ""
  }
}

# API Gateway stage deployment is created in jakshwealth-api automation_codes/terraforms/gw_deploy/
