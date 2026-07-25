/* JakshWealth UI Outputs*/
output "website_bucket_name" {
  value = module.jakshwealth-ui-infra.website_bucket_name
}

output "cf_endpoint" {
  value = module.jakshwealth-ui-infra.cf_endpoint
}

output "cf_hosted_zone_id" {
  value = module.jakshwealth-ui-infra.cf_hosted_zone_id
}
