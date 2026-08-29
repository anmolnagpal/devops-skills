terraform {
  required_version = "~> 1.14"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  backend "s3" {
    bucket         = "acme-tfstate"
    key            = "env/prod/logging.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "acme-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

locals {
  tags = {
    Name        = "acme-prod-logging"
    Environment = "prod"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

# Destination for the account's CloudTrail events. Retention is set, but there is
# no kms_key_id: the audit record is encrypted only with the AWS-owned default key,
# not a CMK this account controls.
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/acme-prod-audit"
  retention_in_days = 365
  tags              = local.tags
}
