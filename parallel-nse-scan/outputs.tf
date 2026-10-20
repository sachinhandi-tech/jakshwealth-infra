output "load_balancer_dns" {
  description = "Public DNS of the parallel scan load balancer."
  value       = aws_lb.parallel.dns_name
}

output "autoscaling_group" {
  description = "Auto Scaling group that keeps average CPU near the target."
  value       = aws_autoscaling_group.parallel.name
}

output "vpc_id" {
  description = "Parallel VPC id. This is not the production VPC."
  value       = aws_vpc.parallel.id
}

output "security_group_id" {
  description = "Instance security group. Inbound TCP 8080 is allowed only from the load balancer."
  value       = aws_security_group.parallel.id
}

output "state_key" {
  description = "S3 state key for this stack. Production state keys are not used."
  value       = "dev/parallel-nse-scan/terraform.tfstate"
}
