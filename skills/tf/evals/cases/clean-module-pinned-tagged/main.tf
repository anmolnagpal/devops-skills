# Fixture: should produce ZERO findings.
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
    key            = "db/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

variable "region" {
  description = "AWS region for all resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

locals {
  common_tags = {
    Name        = "acme-db"
    Environment = var.environment
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "acme-db"
  engine     = "postgres"
  tags       = local.common_tags
}

output "db_endpoint" {
  description = "RDS instance endpoint"
  value       = module.db.db_instance_endpoint
}
