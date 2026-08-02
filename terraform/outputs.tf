output "public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP address of the EC2 instance"
}
