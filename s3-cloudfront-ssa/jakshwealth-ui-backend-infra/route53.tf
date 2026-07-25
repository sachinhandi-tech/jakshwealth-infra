resource "aws_route53_record" "jakshwealth-ui-alias" {
  zone_id = data.aws_route53_zone.zone.id
  name    = "ssa.${local.domain_name}"
  type    = "A"

  alias {
    name = var.cf-domain_name
    zone_id = var.cf-hostedzone
    evaluate_target_health = false
  }
}
