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

# The bucket this account's trail writes to. It is declared and owned here, so
# its durability is this repo's responsibility — yet nothing stops it being
# emptied: no versioning, no Object Lock. Delete the objects and the trail is gone.
resource "aws_s3_bucket" "audit_logs" {
  bucket = "acme-prod-cloudtrail-logs"
  tags   = local.tags

  lifecycle {
    prevent_destroy = true
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
  is_multi_region_trail         = false # only the home region is ever recorded
  enable_logging                = true
  # enable_log_file_validation left off: no tamper-evidence on the log files
  tags = local.tags
}

# tf-skill:ignore TF-MOD-001 -- see note above
resource "aws_eks_cluster" "platform" {
  name     = "acme-prod-platform"
  role_arn = var.eks_cluster_role_arn
  version  = "1.31"

  # "audit" is missing: control-plane API calls leave no audit record
  enabled_cluster_log_types = ["api", "authenticator"]

  vpc_config {
    subnet_ids = var.private_subnet_ids
  }

  tags = local.tags
}
