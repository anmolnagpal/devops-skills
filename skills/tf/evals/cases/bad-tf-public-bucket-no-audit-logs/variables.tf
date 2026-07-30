variable "region" {
  type        = string
  description = "AWS region for this environment."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the platform VPC."
}

variable "private_subnet_cidr" {
  type        = string
  description = "CIDR block for the private subnet."
}
