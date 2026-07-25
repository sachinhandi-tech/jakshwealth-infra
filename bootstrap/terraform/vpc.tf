# Optional VPC for Lambda functions that need private network access.
# Personal deploys use enable_lambda_vpc=false in jakshwealth-api (no NAT required).

resource "aws_vpc" "jakshwealth" {
  count                = var.create_vpc ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(local.tags, { Name = "jakshwealth-vpc" })
}

resource "aws_internet_gateway" "jakshwealth" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.jakshwealth[0].id
  tags   = merge(local.tags, { Name = "jakshwealth-igw" })
}

resource "aws_subnet" "lambda_a" {
  count                   = var.create_vpc ? 1 : 0
  vpc_id                  = aws_vpc.jakshwealth[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "jakshwealth-subnet-001" })
}

resource "aws_subnet" "lambda_b" {
  count                   = var.create_vpc ? 1 : 0
  vpc_id                  = aws_vpc.jakshwealth[0].id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 2)
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "jakshwealth-pod-subnet-001" })
}

resource "aws_route_table" "public" {
  count  = var.create_vpc ? 1 : 0
  vpc_id = aws_vpc.jakshwealth[0].id
  tags   = merge(local.tags, { Name = "jakshwealth-public-rt" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jakshwealth[0].id
  }
}

resource "aws_route_table_association" "lambda_a" {
  count          = var.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.lambda_a[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "lambda_b" {
  count          = var.create_vpc ? 1 : 0
  subnet_id      = aws_subnet.lambda_b[0].id
  route_table_id = aws_route_table.public[0].id
}
