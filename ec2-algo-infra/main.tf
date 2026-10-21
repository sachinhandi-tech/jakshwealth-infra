locals {
  name = "kite-algo-setup"
  tags = {
    Name        = "kite-algo-setup"
    Project     = "jakshwealth"
    Environment = "Parallel-Test"
    ManagedBy   = "terraform-kite-algo-setup"
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

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
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
  for_each = {
    a = 0
    b = 1
  }

  vpc_id                  = aws_vpc.parallel.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 1)
  availability_zone       = data.aws_availability_zones.available.names[each.value]
  map_public_ip_on_launch = true
  tags                    = merge(local.tags, { Name = "${local.name}-subnet-${each.key}" })
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
  for_each       = aws_subnet.parallel
  subnet_id      = each.value.id
  route_table_id = aws_route_table.parallel.id
}

resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Parallel scan load balancer. TCP 80 from the tester CIDR only."
  vpc_id      = aws_vpc.parallel.id
  tags        = merge(local.tags, { Name = "${local.name}-alb" })

  ingress {
    description = "HTTP from the tester"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }
}

resource "aws_security_group_rule" "cloudfront_to_alb" {
  type              = "ingress"
  description       = "HTTP from CloudFront"
  security_group_id = aws_security_group.alb.id
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
}

resource "aws_security_group" "parallel" {
  name        = local.name
  description = "kite-algo-setup instances. TCP 8080 from the load balancer only."
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

resource "aws_security_group_rule" "alb_to_instances" {
  type                     = "egress"
  description              = "Forward to scan instances"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.parallel.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "scan_ingress" {
  type                     = "ingress"
  description              = "Scan service from the load balancer"
  security_group_id        = aws_security_group.parallel.id
  source_security_group_id = aws_security_group.alb.id
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
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

resource "aws_iam_role_policy" "parallel_api" {
  name = "${local.name}-api"
  role = aws_iam_role.parallel.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = [
          "arn:aws:s3:::${var.artifact_bucket}/kite-algo-setup/*",
          "arn:aws:s3:::${var.artifact_bucket}/kite-session/*",
          "arn:aws:s3:::${var.artifact_bucket}/kite-scanner/*",
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:PutObject"]
        Resource = [
          "arn:aws:s3:::${var.artifact_bucket}/kite-session/*",
          "arn:aws:s3:::${var.artifact_bucket}/kite-scanner/*",
          "arn:aws:s3:::${var.ui_bucket}/kite-api-base.json",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.db_secret_id}*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "parallel" {
  name = local.name
  role = aws_iam_role.parallel.name
  tags = local.tags
}

resource "aws_lb" "parallel" {
  name                       = local.name
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.alb.id]
  subnets                    = [for subnet in aws_subnet.parallel : subnet.id]
  enable_deletion_protection = false
  idle_timeout               = 120
  tags                       = local.tags
}

resource "aws_lb_target_group" "parallel" {
  name                 = local.name
  port                 = 8080
  protocol             = "HTTP"
  vpc_id               = aws_vpc.parallel.id
  target_type          = "instance"
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = local.tags
}

resource "aws_lb_listener" "parallel" {
  load_balancer_arn = aws_lb.parallel.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.parallel.arn
  }
}

resource "aws_launch_template" "parallel" {
  name          = local.name
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.parallel.name
  }

  vpc_security_group_ids = [aws_security_group.parallel.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tftpl", {
    breakout_b64      = base64gzip(file("${path.module}/app/breakout.py"))
    market_b64        = base64gzip(file("${path.module}/app/market.py"))
    server_b64        = base64gzip(file("${path.module}/app/server.py"))
    api_base_url      = "https://${aws_cloudfront_distribution.api.domain_name}"
    ui_bucket         = var.ui_bucket
    artifact_bucket   = var.artifact_bucket
    db_secret_id      = var.db_secret_id
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type           = "gp3"
      volume_size           = var.root_volume_gb
      encrypted             = true
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }

  tags = local.tags
}

resource "aws_autoscaling_group" "parallel" {
  lifecycle {
    precondition {
      condition     = var.asg_max_size >= var.asg_min_size
      error_message = "asg_max_size must be at least asg_min_size."
    }
  }

  name                      = local.name
  vpc_zone_identifier       = [for subnet in aws_subnet.parallel : subnet.id]
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  desired_capacity          = var.asg_min_size
  health_check_type         = "ELB"
  health_check_grace_period = 420
  default_instance_warmup   = 420
  target_group_arns         = [aws_lb_target_group.parallel.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 420
    }
  }

  launch_template {
    id      = aws_launch_template.parallel.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [aws_route.parallel_default, aws_lb_listener.parallel]
}

# Custom cache policy to preserve CORS headers
resource "aws_cloudfront_cache_policy" "api_cors" {
  name        = "${local.name}-cors-cache"
  comment     = "Cache policy that preserves CORS headers"
  default_ttl = 0
  max_ttl     = 86400
  min_ttl     = 0
  
  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "whitelist"
      headers {
        items = [
          "Access-Control-Allow-Origin",
          "Access-Control-Allow-Methods",
          "Access-Control-Allow-Headers",
          "Access-Control-Expose-Headers",
          "Origin",
          "Authorization"
        ]
      }
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_distribution" "api" {
  enabled         = true
  is_ipv6_enabled = false
  comment         = "HTTPS entry for the kite-algo-setup API"
  price_class     = "PriceClass_200"

  origin {
    domain_name = aws_lb.parallel.dns_name
    origin_id   = "${local.name}-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
      origin_read_timeout    = 60
    }
  }

  default_cache_behavior {
    allowed_methods          = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods           = ["GET", "HEAD"]
    target_origin_id         = "${local.name}-alb"
    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = aws_cloudfront_cache_policy.api_cors.id
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
    compress                 = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = local.tags
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.name}-cpu"
  autoscaling_group_name = aws_autoscaling_group.parallel.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value     = var.cpu_target_percent
    disable_scale_in = false
  }
}
