output "endpoint" {
  value = aws_db_instance.postgres.address
}

output "database_name" {
  value = aws_db_instance.postgres.db_name
}

output "secret_name" {
  value = aws_secretsmanager_secret.postgres.name
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
