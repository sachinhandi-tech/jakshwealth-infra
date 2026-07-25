output "jw_api_gateway_rest_api_name" {
  value = aws_api_gateway_rest_api.main_jw_api.name
}

output "jw_api_gateway_domain_name" {
  value = var.enable_custom_domain ? aws_api_gateway_domain_name.jwapi_gatewaydns[0].domain_name : aws_api_gateway_rest_api.main_jw_api.execution_arn
}

output "jw_api_gateway_rest_api_execution_arn" {
  value = aws_api_gateway_rest_api.main_jw_api.execution_arn
}

output "jw_authorization_authorizer_id" {
  value = aws_api_gateway_authorizer.jw_authorization.id
}
