resource "aws_route53_record" "jwapi_gateway_r53" {
  count   = var.enable_custom_domain ? 1 : 0
  name    = aws_api_gateway_domain_name.jwapi_gatewaydns[0].domain_name
  type    = "A"
  zone_id = var.hosted_zone_id

  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.jwapi_gatewaydns[0].regional_domain_name
    zone_id                = aws_api_gateway_domain_name.jwapi_gatewaydns[0].regional_zone_id
  }
}
