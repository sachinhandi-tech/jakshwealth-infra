variable "deploy_env" {
  default = ""
}

variable "ssa_ui_website_resources" {
	type = list(string)
}

variable "ssa_ui_website_users" {
  type = list(string)
}


variable "cigna_tags" {
  type = map
}

variable "cf-domain_name" {
  default = ""
}

variable "cf-hostedzone" {
  default = ""
}

variable "owner_canonical_id" {
  type        = string
  description = "canonical for s3"
}
