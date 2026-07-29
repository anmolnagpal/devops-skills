# No terraform/backend block at all: state lands wherever the operator ran it.
provider "aws" {
  region = "eu-west-1"
}

module "aurora" {
  source  = "clouddrove/aurora/aws"
  version = "1.0.5"

  name        = "acme-dev-aurora"
  environment = "dev"
  label_order = ["name"]

  engine            = "aurora-postgresql"
  engine_version    = "16.4"
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key for Aurora storage encryption."
}
