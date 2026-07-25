variable "jw_api_name" {
  description = "Name of the JakshWealth REST API"
  default     = "jw-api"
}

variable "route53name_jw_api" {
  description = "Route53 name prefix for the JakshWealth API custom domain"
  default     = "jw-api"
}

variable "api_domain_suffix" {
  description = "DNS suffix for the API custom domain (e.g. jakshwealth-dev.example.com)"
  type        = string
}

variable "jw_authorizer_lambda_name" {
  description = "JakshWealth API Gateway TOKEN authorizer Lambda (jw_authorization_{environment})"
  default     = ""
}

variable "enable_custom_domain" {
  type    = bool
  default = false
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for API DNS (when enable_custom_domain is true)"
  default     = ""
}

variable "certificate_arn_api" {
  description = "ACM certificate ARN for the API custom domain"
  default     = ""
}

variable "project_tags" {
  description = "Tags applied to JakshWealth infrastructure resources"
  type        = map(string)
  default = {
    project      = "JakshWealth"
    ResourceName = "jakshwealth"
  }
}

variable "environment" {
  description = "Deployment environment (dev, test, prod)"
}

variable "cors_response_params" {
  type        = map(string)
  description = "Gateway response parameters for CORS"
  default = {
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,authorizationToken,auth_code,refresh_token'",
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,PATCH,HEAD,DELETE'",
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

variable "api_gw_tags" {
  description = "Additional API Gateway tags"
  type        = map(string)
  default     = {}
}
