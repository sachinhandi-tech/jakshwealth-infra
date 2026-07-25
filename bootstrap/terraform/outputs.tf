output "infra_bucket" {
  value = try(aws_s3_bucket.foundation["infra"].id, null)
}

output "artifacts_bucket" {
  value = try(aws_s3_bucket.foundation["artifacts"].id, null)
}

output "logs_bucket" {
  value = try(aws_s3_bucket.foundation["logs"].id, null)
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "vpc_id" {
  value = var.create_vpc ? try(aws_vpc.jakshwealth[0].id, null) : null
}
