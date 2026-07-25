variable "rest_api_id" {
  description = "Api gateway Rest api id"
}
variable "resource_id" {
  description = "parent root Id of Rest api"
}

variable "method" {
  description = "method type of the request"
  default = "GET"
}
variable "lambda" {
  description = "Reference for lambda function"
}
variable "path" {
  description = "API source path"
}
variable "region" {
  description = "The AWS region, e.g., eu-west-1"
}

variable "account_id" {
  description = "The AWS account ID"
}
variable "stage" {
  description = "The stage of api gateway i.e dev prod etc"
}
variable "response_parameters" {
  type = map
  default = { "method.response.header.Access-Control-Allow-Origin" = true }
}
variable "response_models" {
  type = map
  
  default = {
    "application/json" = "Empty"
  }
} 
variable "authorization" {
  type = string
  description = "authorizer required"
  default = "true"
}
variable "auth_request_param" {
  type = map(string)
  description = "If authorizer is not None"
  default = {
    "method.request.path.proxy" = true
  }
}
