output "vpc_id" {
  description = "ID of the HomePulse VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the HomePulse security group"
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