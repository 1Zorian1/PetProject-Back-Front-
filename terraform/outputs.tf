output "ec2_public_ip" {
  description = "Публічна IP-адреса створеного сервера EC2"
  value       = aws_instance.app_server.public_ip
}

output "ssh_connection_command" {
  description = "Команда для підключення через SSH"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.app_server.public_ip}"
}
