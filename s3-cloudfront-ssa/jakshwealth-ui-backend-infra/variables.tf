variable "deploy_env" {
  default = ""
}

variable "domain_name" {
  type = map
  default = {
    dev = "jakshwealth-dev.aws.cignacloud.com"
    test = "jakshwealth-test.aws.cignacloud.com"
    prod = "jakshwealth-prod.aws.cignacloud.com"
  }
}

variable "artifacts_bucket" {
  type = map
  default = {
    dev = "cigna-us-jakshwealth-artifacts-dev"
    test = "cigna-us-jakshwealth-artifacts-test"
    prod = "cigna-us-jakshwealth-artifacts-prod"
  }
}

variable "infra_state_bucket" {
  type = map
  default = {
    dev = "cigna-us-jakshwealth-infra-dev"
    test = "cigna-us-jakshwealth-infra-test"
    prod = "cigna-us-jakshwealth-infra-prod"
  }
}

variable "alert_funnel_arn" {
  type = map
  default = {
    dev = "arn:aws:sns:us-east-1:929468956630:cloudwatch-alarm-funnel"
    test = "arn:aws:sns:us-east-1:929468956630:cloudwatch-alarm-funnel"
    prod = "arn:aws:sns:us-east-1:746770431074:cloudwatch-alarm-funnel"
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
