# No terraform{} block anywhere in this file: no required_version, no
# required_providers, and the backend below is the only terraform config present.
terraform {
  backend "s3" {
    bucket = "acme-tfstate"
    key    = "env/prod/network.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=master"

  name = "acme-prod-vpc"
  cidr = var.vpc_cidr

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Name        = "acme-prod-vpc"
    Environment = "prod"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret" "db" {
  name = "acme-prod-db-credentials"

  tags = {
    Name        = "acme-prod-db-credentials"
    Environment = "prod"
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = var.db_credentials_json
}

output "db_credentials" {
  description = "Database credentials JSON, consumed by the app pipeline."
  value       = aws_secretsmanager_secret_version.db.secret_string
}

output "vpc_id" {
  description = "VPC identifier."
  value       = module.vpc.vpc_id
}
