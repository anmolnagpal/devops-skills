# Fixture: correct wrapper pattern, but the IAM policy it provisions is wildcard
# and has no MFA condition. Not real infrastructure.
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "labels" {
  source         = "../labels"
  client_name    = var.client_name
  environment    = var.environment
  repository_url = var.repository_url
  cost_center    = var.cost_center
}

locals {
  np = module.labels.name_prefix
}

variable "client_name" {
  type        = string
  description = "Client slug — used as resource name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "repository_url" {
  type        = string
  description = "Source repository URL — applied as a tag."
}

variable "cost_center" {
  type        = string
  description = "Cost center code — applied as a tag."
}

resource "aws_iam_group" "admins" {
  name = "${local.np}-admins"
}

resource "aws_iam_group_policy" "admins_wildcard" {
  name  = "${local.np}-admins-wildcard"
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
  description = "Admins IAM group ARN."
  value       = aws_iam_group.admins.arn
}
