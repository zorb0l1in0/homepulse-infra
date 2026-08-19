output "vpc_id" {
  description = "ID of the HomePulse VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of public subnet A"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the EC2 security group"
  value       = aws_security_group.homepulse.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.homepulse.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.homepulse.public_ip
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i homepulse-key.pem ubuntu@${aws_instance.homepulse.public_ip}"
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.homepulse.dns_name
}

output "acm_validation_records" {
  description = "DNS records to add in Aruba for ACM certificate validation"
  value = {
    for dvo in aws_acm_certificate.homepulse.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
}

output "grafana_url" {
  description = "Grafana URL via ALB"
  value       = "https://${var.domain_name}"
}
