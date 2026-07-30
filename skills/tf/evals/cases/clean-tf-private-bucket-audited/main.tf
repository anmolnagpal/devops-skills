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
    key            = "env/prod/platform.tfstate"
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
    Name        = "acme-prod-platform"
    Environment = "prod"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "customer_documents" {
  bucket = "acme-prod-customer-documents"
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "customer_documents" {
  bucket                  = aws_s3_bucket.customer_documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudtrail" "account" {
  name                          = "acme-prod-account-trail"
  s3_bucket_name                = var.audit_log_bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  tags                          = local.tags
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = local.tags
}

resource "aws_flow_log" "main" {
  vpc_id               = aws_vpc.main.id
  traffic_type         = "ALL"
  log_destination      = var.flow_log_bucket_arn
  log_destination_type = "s3"
  tags                 = local.tags
}
