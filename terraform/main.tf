terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.80.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ==================== VARIABLES ====================

variable "aws_region" {
  type        = string
  default     = "eu-central-1"
  description = "AWS Region"
}

variable "public_key" {
  type        = string
  description = "Public SSH key passed from GitHub Secrets"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 Instance Type"
}

# ==================== RESOURCES ====================

# 1. SSH Key Pair для доступу до EC2
resource "aws_key_pair" "deployer" {
  key_name   = "petproject-deployer-key"
  public_key = var.public_key
}

# 2. Security Group (Мережеві правила)
resource "aws_security_group" "web_sg" {
  name        = "petproject-web-sg"
  description = "Allow HTTP, API and SSH traffic"

  # SSH доступ
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP (Frontend)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API (Backend)
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Дозволяємо весь вихідний трафік (щоб EC2 міг скачувати пакети та Docker-образи)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "petproject-web-sg"
  }
}

# 3. Знаходимо найновіший AMI Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# 4. Створення EC2 Інстансу
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Автоматичне встановлення Docker та Docker Compose при запуску сервера
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y ca-certificates curl gnupg lsb-release
              
              # Встановлення Docker
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

              # Додаємо дефолтного юзера ubuntu в групу docker
              usermod -aG docker ubuntu
              systemctl enable docker
              systemctl start docker
              EOF

  tags = {
    Name = "PetProject-Server"
  }
}

# ==================== OUTPUTS ====================

# Виводимо публічну IP-адресу після створення сервера
output "public_ip" {
  value       = aws_instance.web.public_ip
  description = "Public IP address of the EC2 instance"
}
