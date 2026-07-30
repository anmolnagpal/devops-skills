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

# Customer document store. Nothing about this is meant to be public.
resource "aws_s3_bucket" "customer_documents" {
  bucket = "acme-prod-customer-documents"
  tags   = local.tags
}

resource "aws_s3_bucket_acl" "customer_documents" {
  bucket = aws_s3_bucket.customer_documents.id
  acl    = "public-read"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = local.tags
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr
  tags       = local.tags
}
