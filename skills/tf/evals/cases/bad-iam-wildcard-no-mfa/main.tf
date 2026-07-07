# Fixture: wildcard IAM policy + no MFA condition on a human-facing group. Not real infrastructure.
terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "acme-tfstate"
    key            = "iam/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

locals {
  common_tags = {
    Name        = "acme-iam"
    Environment = var.environment
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_group" "admins" {
  name = "admins"
}

resource "aws_iam_group_policy" "admins_wildcard" {
  name  = "admins-wildcard"
  group = aws_iam_group.admins.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      }
    ]
  })
}

output "admins_group_arn" {
  description = "Admins IAM group ARN"
  value       = aws_iam_group.admins.arn
}
