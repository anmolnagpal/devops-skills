terraform {
  backend "s3" {
    bucket = "acme-tfstate"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "aurora" {
  source = "../../_modules/aurora"

  client_name = "acme"
  environment = "prod"
  kms_key_arn = var.kms_key_arn
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key for Aurora storage encryption."
}
