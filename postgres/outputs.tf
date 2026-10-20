output "endpoint" {
  value = aws_db_instance.postgres.address
}

output "database_name" {
  value = aws_db_instance.postgres.db_name
}

output "secret_name" {
  value = aws_secretsmanager_secret.postgres.name
}

output "vpc_id" {
  value = aws_vpc.postgres.id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "kite_private_route_table_id" {
  value = aws_route_table.kite_private.id
}

output "kite_private_subnet_ids" {
  value = aws_subnet.kite_private[*].id
}

output "kite_lambda_security_group_id" {
  value = aws_security_group.kite_lambda.id
}

output "postgres_security_group_id" {
  value = aws_security_group.postgres.id
}
