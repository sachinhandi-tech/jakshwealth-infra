/* HPP JakshWealth UI Outputs*/
output "website_bucket_name" {
  value = module.jakshwealth-ui-infra.website_bucket_name
}

output "hpp-cf-endpoint" {
  value = module.jakshwealth-ui-infra.hpp-cf-endpoint
}

output "hpp-cf-hostedzone" {
  value = module.jakshwealth-ui-infra.hpp-cf-hostedzone
}
