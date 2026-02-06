# ALB DNS Name - Primary access point for Strapi
output "strapi_url" {
  description = "URL for the Strapi application via ALB"
  value       = "http://${aws_lb.strapi_alb.dns_name}"
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.strapi_alb.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB for Route53 alias records"
  value       = aws_lb.strapi_alb.zone_id
}

# VPC Information
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

# EC2 Instance
output "ec2_instance_id" {
  description = "ID of the Strapi EC2 instance (use for SSM Session Manager)"
  value       = aws_instance.strapi_app.id
}

output "ec2_private_ip" {
  description = "Private IP of the Strapi EC2 instance"
  value       = aws_instance.strapi_app.private_ip
}

# SSM Connection Command
output "ssm_connect_command" {
  description = "AWS CLI command to connect via Session Manager"
  value       = "aws ssm start-session --target ${aws_instance.strapi_app.id}"
}
