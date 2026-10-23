terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_rds_engine_version" "postgres" {
  engine  = "postgres"
  version = "16"
  latest  = true
}

resource "random_password" "db" {
  length  = 32
  special = false
}

resource "random_bytes" "fernet" {
  length = 32
}

resource "random_password" "state" {
  length  = 48
  special = false
}

locals {
  name = "jakshwealth-${var.environment}-postgres"
  tags = {
    Project     = "jakshwealth"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
  fernet_key = replace(replace(random_bytes.fernet.base64, "+", "-"), "/", "_")
}

resource "aws_vpc" "postgres" {
  cidr_block           = "10.40.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = local.name })
}

resource "aws_internet_gateway" "postgres" {
  vpc_id = aws_vpc.postgres.id
  tags   = merge(local.tags, { Name = "${local.name}-igw" })
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.postgres.id
  cidr_block              = cidrsubnet(aws_vpc.postgres.cidr_block, 8, count.index + 1)
  availability_zone       = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${local.name}-public-${count.index + 1}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.postgres.id
  tags   = merge(local.tags, { Name = "${local.name}-public" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.postgres.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_db_subnet_group" "postgres" {
  name       = local.name
  subnet_ids = aws_subnet.public[*].id
  tags       = local.tags
}

resource "aws_security_group" "postgres" {
  name        = local.name
  description = "Postgres for JakshWealth subscriber sessions"
  vpc_id      = aws_vpc.postgres.id
  tags        = local.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kite_lambda" {
  name        = "${local.name}-kite-lambda"
  description = "jw_kite in the existing Postgres VPC"
  vpc_id      = aws_vpc.postgres.id
  tags        = local.tags

  egress {
    description = "HTTPS for Kite, Secrets Manager, and S3 through the NAT gateway"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "kite_lambda_to_postgres" {
  type                     = "egress"
  description              = "Postgres"
  security_group_id        = aws_security_group.kite_lambda.id
  source_security_group_id = aws_security_group.postgres.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "postgres_from_kite_lambda" {
  type                     = "ingress"
  description              = "Postgres from jw_kite"
  security_group_id        = aws_security_group.postgres.id
  source_security_group_id = aws_security_group.kite_lambda.id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
}

resource "aws_eip" "kite_nat" {
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${local.name}-nat" })
}

resource "aws_nat_gateway" "kite" {
  allocation_id = aws_eip.kite_nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(local.tags, { Name = "${local.name}-nat" })
  depends_on    = [aws_internet_gateway.postgres]
}

resource "aws_subnet" "kite_private" {
  count                   = 2
  vpc_id                  = aws_vpc.postgres.id
  cidr_block              = cidrsubnet(aws_vpc.postgres.cidr_block, 8, count.index + 11)
  availability_zone       = "${var.aws_region}${count.index == 0 ? "a" : "b"}"
  map_public_ip_on_launch = false
  tags                    = merge(local.tags, { Name = "${local.name}-kite-private-${count.index + 1}" })
}

resource "aws_route_table" "kite_private" {
  vpc_id = aws_vpc.postgres.id
  tags   = merge(local.tags, { Name = "${local.name}-kite-private" })

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.kite.id
  }
}

resource "aws_route_table_association" "kite_private" {
  count          = 2
  subnet_id      = aws_subnet.kite_private[count.index].id
  route_table_id = aws_route_table.kite_private.id
}

resource "aws_db_parameter_group" "postgres" {
  name   = local.name
  family = "postgres16"
  tags   = local.tags

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }
}

resource "aws_db_instance" "postgres" {
  identifier                 = local.name
  engine                     = "postgres"
  engine_version             = data.aws_rds_engine_version.postgres.version
  instance_class             = "db.t4g.micro"
  allocated_storage          = 20
  max_allocated_storage      = 100
  db_name                    = "jakshwealth"
  username                   = "jakshwealth_app"
  password                   = random_password.db.result
  db_subnet_group_name       = aws_db_subnet_group.postgres.name
  vpc_security_group_ids     = [aws_security_group.postgres.id]
  parameter_group_name       = aws_db_parameter_group.postgres.name
  publicly_accessible        = true
  storage_encrypted          = true
  backup_retention_period    = 7
  deletion_protection        = true
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${local.name}-final"
  auto_minor_version_upgrade = true
  apply_immediately          = true
  tags                       = local.tags
}

resource "aws_secretsmanager_secret" "jakshwealth" {
  name = "jakshwealth/${var.environment}/jakshwealth"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.jakshwealth.id
  secret_string = jsonencode({
    username     = aws_db_instance.postgres.username
    password     = random_password.db.result
    host         = aws_db_instance.postgres.address
    port         = aws_db_instance.postgres.port
    dbname       = aws_db_instance.postgres.db_name
    url          = "postgresql+psycopg://${aws_db_instance.postgres.username}:${random_password.db.result}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}?sslmode=require"
    fernet_key      = local.fernet_key
    state_secret    = random_password.state.result
    kite_api_key    = var.kite_api_key
    kite_api_secret = var.kite_api_secret
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

data "aws_iam_roles" "kite" {
  name_regex = "^JW_jw_kite_${var.environment}$"
}

resource "aws_iam_role_policy" "kite_scan_invoke" {
  count = length(data.aws_iam_roles.kite.names) > 0 ? 1 : 0
  name  = "jakshwealth-${var.environment}-kite-scan-invoke"
  role  = tolist(data.aws_iam_roles.kite.names)[0]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["lambda:InvokeFunction"]
      Resource = "arn:aws:lambda:${var.aws_region}:*:function:jw_kite"
    }]
  })
}

resource "aws_iam_role_policy" "kite_db" {
  count = length(data.aws_iam_roles.kite.names) > 0 ? 1 : 0
  name  = "jakshwealth-${var.environment}-postgres-read"
  role  = tolist(data.aws_iam_roles.kite.names)[0]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = aws_secretsmanager_secret.jakshwealth.arn
    }]
  })
}
