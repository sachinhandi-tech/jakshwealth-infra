output "infra_bucket" {
  value = aws_s3_bucket.foundation["infra"].id
}

output "artifacts_bucket" {
  value = aws_s3_bucket.foundation["artifacts"].id
}

output "logs_bucket" {
  value = aws_s3_bucket.foundation["logs"].id
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "vpc_id" {
  value = var.create_vpc ? aws_vpc.jakshwealth[0].id : null
}
