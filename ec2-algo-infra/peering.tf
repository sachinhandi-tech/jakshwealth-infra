# The subscriber database stays in its existing VPC. A new instance publishes its
# public address before nginx starts, so the desk is not switched over while Postgres is closed.

data "terraform_remote_state" "postgres" {
  backend = "s3"
  config = {
    bucket         = "jakshwealth-infra-dev-aps2"
    key            = "dev/jakshwealth-postgres/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = "terraform-state-lock"
  }
}

resource "aws_vpc_peering_connection" "postgres" {
  vpc_id      = aws_vpc.parallel.id
  peer_vpc_id = data.terraform_remote_state.postgres.outputs.vpc_id
  auto_accept = true
  tags        = merge(local.tags, { Name = "${local.name}-postgres" })
}

resource "aws_route" "parallel_to_postgres" {
  route_table_id            = aws_route_table.parallel.id
  destination_cidr_block    = "10.40.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.postgres.id
}

resource "aws_route" "postgres_public_to_parallel" {
  route_table_id            = data.terraform_remote_state.postgres.outputs.public_route_table_id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.postgres.id
}

resource "aws_route" "postgres_private_to_parallel" {
  route_table_id            = data.terraform_remote_state.postgres.outputs.kite_private_route_table_id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.postgres.id
}

resource "aws_security_group_rule" "instances_to_postgres" {
  type                     = "egress"
  description              = "Postgres in the subscriber VPC"
  security_group_id        = aws_security_group.parallel.id
  source_security_group_id = data.terraform_remote_state.postgres.outputs.postgres_security_group_id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  depends_on               = [aws_vpc_peering_connection.postgres]
}

resource "aws_security_group_rule" "postgres_from_instances" {
  type                     = "ingress"
  description              = "Postgres from kite-algo-setup"
  security_group_id        = data.terraform_remote_state.postgres.outputs.postgres_security_group_id
  source_security_group_id = aws_security_group.parallel.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  depends_on               = [aws_vpc_peering_connection.postgres]
}
