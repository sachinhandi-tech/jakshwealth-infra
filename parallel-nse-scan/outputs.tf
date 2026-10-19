output "instance_id" {
  description = "Parallel EC2 instance id."
  value       = aws_instance.parallel.id
}

output "public_ip" {
  description = "Public IPv4 used by validate_parallel.py."
  value       = aws_instance.parallel.public_ip
}

output "private_ip" {
  description = "Private IPv4 inside the parallel VPC."
  value       = aws_instance.parallel.private_ip
}

output "vpc_id" {
  description = "Parallel VPC id. This is not the production VPC."
  value       = aws_vpc.parallel.id
}

output "security_group_id" {
  description = "Security group that allows TCP 8080 only from allowed_cidr."
  value       = aws_security_group.parallel.id
}

output "state_path" {
  description = "Local state file for this stack. Production remote state is not used."
  value       = "parallel-test.tfstate"
}
