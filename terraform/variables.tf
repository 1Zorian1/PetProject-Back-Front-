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
