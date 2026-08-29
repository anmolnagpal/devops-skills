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
    key            = "env/prod/edge.tfstate"
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
    Name        = "acme-prod-edge"
    Environment = "prod"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

# Public entry point for the app. It terminates every external request, yet
# access_logs is absent: there is no record of which client hit which path.
# tf-skill:ignore TF-MOD-001 -- raw aws_lb declared directly to isolate the
# access-log check; no abstraction we reuse here
resource "aws_lb" "public" {
  name               = "acme-prod-public"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = local.tags
}
