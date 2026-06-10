# Fixture: multiple BLOCKING + ADVISORY violations. Not real infrastructure.
terraform {
  required_version = "~> 1.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
  # no backend block
}

variable "region" {
  default = "eu-west-1"
}

resource "aws_db_instance" "db" {
  engine   = "postgres"
  password = "hunter2"
  region   = "eu-west-1"
}

output "db_endpoint" {
  value = aws_db_instance.db.endpoint
}
