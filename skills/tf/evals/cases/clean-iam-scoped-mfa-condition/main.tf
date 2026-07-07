# Fixture: scoped IAM policy with an explicit MFA condition. Should produce ZERO findings.
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

resource "aws_iam_group" "billing_admins" {
  name = "billing-admins"
}

resource "aws_iam_group_policy" "billing_admins_scoped" {
  name  = "billing-admins-scoped"
  group = aws_iam_group.billing_admins.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["aws-portal:*Billing", "aws-portal:*Usage"]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })
}

output "billing_admins_group_arn" {
  description = "Billing admins IAM group ARN"
  value       = aws_iam_group.billing_admins.arn
}
