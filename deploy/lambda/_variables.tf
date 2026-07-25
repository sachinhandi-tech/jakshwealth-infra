variable "function_name" {
  description = "Bucket name to deployment path of artifacts."
}

variable "description" {
  description = "Description of lambda function"
}

variable "role"{
  description = "Role for lambda function"
  default = null
}

variable "s3artifactbucket" {
  description = "Bucket name to deployment path of artifacts."
}

variable "s3artifactkey"{
  description = "Key for deployment artifact path - usually something like : project-name/function-name/version/file.zip"
}

variable "handler"{
  description = "Name of the handler file"
  default = "handler.handler"
}

/* upgraded to 3.9 runtime for all lambdas */
variable "runtime" {
  description = "Runtime environment"
  default = "python3.12"
}

variable "timeout"{
  description = "The amount of time your Lambda Function has to run in seconds. Defaults to 3 minutes."
  default = 3
}

variable "memory_size" {
  default = 128
}

variable "ephemeral_memory" {
  default = 512
}

variable "reserved_concurrent_executions"{
  description = "The amount of reserved concurrent executions for this lambda function. A value of 0 disables lambda from being triggered and -1 removes any concurrency limitations. Defaults to Unreserved Concurrency Limits -1."
  default = "-1"
}

variable "environment" {
  description = "Code environment."
  default = "dev"
}

variable "environmental_variables" {
  description = "Variables"
  type = map
  default = {}
}

variable "layers"{
   description = "layers for lambda function"
   type = list
   default = []
}
variable "tags" {
   description = "tags"
   type = map
   default = {}
}
variable "s3objectversion"{
   description = "version of the s3 to be picked up"
   default = null
}
variable "security_group_ids"{
   description = "security group of vpcs"
   type = list
   default = []
}
variable "subnet_ids" {
   description = "subnet ids of vpc"
   type = list
   default = []
}

/* cloudwatch variables */

variable "alert_funnel_arn" {
  description = "arn of funnel to sns topic"
  default = "arn:aws:sns:us-east-1:929468956630:cloudwatch-alarm-funnel"
}

variable "destination_arn" {
  description = "arn of centralized splunk dist"
  default = "arn:aws:logs:us-east-1:746770431074:destination:CentralizedLogging-v2-Destination"
}

variable "appeals_sqs_queue_name" {
  default = "ccd-appeals-fifo-queue"
}

variable "appeal_rerun_queue_name" {
  default = "ccd-appeal-rerun-fifo-queue"
}

variable "enable_log_subscription" {
  default = true
}

variable "period" {
  type = number
  description = "Period of evaluation"
  default = 180 
}

variable "alarm_duration" {
  type = number
  description = "Threshold time limit for lambda processing time. Setting default to 890 seconds."
  default = 890000
}

