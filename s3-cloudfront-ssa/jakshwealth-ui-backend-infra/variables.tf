variable "deploy_env" {
  default = ""
}

variable "enable_custom_domain" {
  type    = bool
  default = false
}

variable "domain_name" {
  type = map
  default = {
    dev  = "jakshwealth-dev.example.com"
    test = "jakshwealth-test.example.com"
    prod = "jakshwealth-prod.example.com"
  }
}

variable "artifacts_bucket" {
  type = map
  default = {
    dev  = "jakshwealth-artifacts-dev"
    test = "jakshwealth-artifacts-test"
    prod = "jakshwealth-artifacts-prod"
  }
}

variable "infra_state_bucket" {
  type = map
  default = {
    dev  = "jakshwealth-infra-dev"
    test = "jakshwealth-infra-test"
    prod = "jakshwealth-infra-prod"
  }
}

variable "alert_funnel_arn" {
  type = map
  default = {
    dev  = ""
    test = ""
    prod = ""
  }
}

variable "cf-domain_name" {
  default = ""
}

variable "cf-hostedzone" {
  default = ""
}

variable "cigna_tags" {
  description = "Maps of tags required for AWS resrource"
  type = map
}
