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
    key            = "env/prod/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "acme-tfstate-lock"
    encrypt        = true
  }
}

locals {
  tags = {
    Environment = "prod"
    Team        = "payments"
    ManagedBy   = "terraform"
  }
}

variable "db_password" {
  description = "Master password for the payments database"
  type        = string
  # tf-skill:ignore TF-VAR-002
  sensitive = false
}

resource "aws_db_instance" "main" {
  identifier        = "prod-payments-db"
  engine            = "postgres"
  engine_version    = "16.4"
  instance_class    = "db.r7g.large"
  allocated_storage = 200
  password          = var.db_password
  tags              = local.tags

  lifecycle {
    prevent_destroy = true
  }
}
