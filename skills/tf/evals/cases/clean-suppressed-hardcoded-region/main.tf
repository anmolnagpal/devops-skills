# Fixture: would trigger TF-VAR-004 but the risk is suppressed with a reason.
# Should produce ZERO findings — the suppression must be honored.
terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "acme-tfstate"
    key            = "single-region-svc/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

locals {
  common_tags = {
    Name        = "single-region-svc"
    Environment = var.environment
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

# tf-skill:ignore TF-VAR-004 -- this service is contractually single-region (data residency); region will never vary by environment
# tf-skill:ignore TF-MOD-001 -- one plain private bucket with no policy, logging, or replication; the module wraps 30 inputs we would all set to defaults
resource "aws_s3_bucket" "archive" {
  bucket = "acme-single-region-archive"
  region = "eu-west-1"
  tags   = local.common_tags
}
