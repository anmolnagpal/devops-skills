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

# Audit-log bucket owned here: versioned and Object-Locked, so the trail is WORM.
resource "aws_s3_bucket" "audit_logs" {
  bucket              = "acme-prod-cloudtrail-logs"
  object_lock_enabled = true
  tags                = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 365
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket                  = aws_s3_bucket.audit_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# tf-skill:ignore TF-MOD-001 -- audit primitives and a minimal EKS shell declared
# directly to isolate the log-integrity checks; no abstraction we reuse here
resource "aws_cloudtrail" "account" {
  name                          = "acme-prod-account-trail"
  s3_bucket_name                = aws_s3_bucket.audit_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  tags                          = local.tags
}

# tf-skill:ignore TF-MOD-001 -- see note above
resource "aws_eks_cluster" "platform" {
  name     = "acme-prod-platform"
  role_arn = var.eks_cluster_role_arn
  version  = "1.31"

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  tags = local.tags
}
