locals {
  name = "jakshwealth-parallel-nse-scan"
  tags = {
    Name        = "jakshwealth-parallel-nse-scan"
    Project     = "jakshwealth"
    Environment = "Parallel-Test"
    ManagedBy   = "terraform-parallel-nse-scan"
  }
  dns_resolver = cidrhost(var.vpc_cidr, 2)
}

data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_vpc" "parallel" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.tags, { Name = "${local.name}-vpc" })
}

resource "aws_internet_gateway" "parallel" {
  vpc_id = aws_vpc.parallel.id
  tags   = merge(local.tags, { Name = "${local.name}-igw" })
}

resource "aws_subnet" "parallel" {
  vpc_id                  = aws_vpc.parallel.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${local.name}-subnet" })
}

resource "aws_route_table" "parallel" {
  vpc_id = aws_vpc.parallel.id
  tags   = merge(local.tags, { Name = "${local.name}-rt" })
}

resource "aws_route" "parallel_default" {
  route_table_id         = aws_route_table.parallel.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.parallel.id
}

resource "aws_route_table_association" "parallel" {
  subnet_id      = aws_subnet.parallel.id
  route_table_id = aws_route_table.parallel.id
}

resource "aws_security_group" "parallel" {
  name        = local.name
  description = "Parallel NSE scan. TCP 8080 from the tester CIDR only."
  vpc_id      = aws_vpc.parallel.id
  tags        = local.tags

  egress {
    description = "HTTPS for Kite, Amazon Linux repositories, and SSM public endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS to the Amazon VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["${local.dns_resolver}/32"]
  }

  egress {
    description = "DNS to the Amazon VPC resolver"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["${local.dns_resolver}/32"]
  }
}

resource "aws_security_group_rule" "scan_ingress" {
  type              = "ingress"
  description       = "Scan service from the tester"
  security_group_id = aws_security_group.parallel.id
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = [var.allowed_cidr]
}

resource "aws_iam_role" "parallel" {
  name               = local.name
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "parallel_ssm" {
  role       = aws_iam_role.parallel.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "parallel" {
  name = local.name
  role = aws_iam_role.parallel.name
  tags = local.tags
}

resource "aws_instance" "parallel" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.parallel.id
  vpc_security_group_ids      = [aws_security_group.parallel.id]
  iam_instance_profile        = aws_iam_instance_profile.parallel.name
  associate_public_ip_address = true
  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    breakout_b64 = base64gzip(file("${path.module}/app/breakout.py"))
    market_b64   = base64gzip(file("${path.module}/app/market.py"))
    server_b64   = base64gzip(file("${path.module}/app/server.py"))
  })
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_gb
    encrypted             = true
    delete_on_termination = true
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = local.tags

  depends_on = [aws_route.parallel_default]
}
