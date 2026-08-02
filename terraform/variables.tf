variable "aws_region" {
  description = "AWS регіон для деплою"
  type        = string
  default     = "eu-central-1" # Франкфурт (можеш змінити на eu-west-1 / eu-north-1)
}

variable "instance_type" {
  description = "Тип EC2 інстансу (входить у Free Tier)"
  type        = string
  default     = "t2.micro" # Якщо в обраному регіоні немає t2.micro, використовуй t3.micro
}

variable "key_name" {
  description = "Назва SSH ключа в AWS для підключення до EC2"
  type        = string
  default     = "devops-ec2-key"
}
