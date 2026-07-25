resource "aws_route53_record" "jakshwealth-ui-alias" {
  count   = var.enable_custom_domain ? 1 : 0
  zone_id = data.aws_route53_zone.zone[0].id
  name    = "app.${local.domain_name}"
  type    = "A"

  alias {
    name = var.cf-domain_name
    zone_id = var.cf-hostedzone
    evaluate_target_health = false
  }
}
