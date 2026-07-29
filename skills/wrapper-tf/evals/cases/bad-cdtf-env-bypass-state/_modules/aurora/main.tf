module "labels" {
  source         = "../labels"
  client_name    = var.client_name
  environment    = var.environment
  repository_url = var.repository_url
  cost_center    = var.cost_center
}

locals {
  np = module.labels.name_prefix
}

module "aurora" {
  source  = "clouddrove/aurora/aws"
  version = "1.0.5"

  name        = "${local.np}-aurora"
  environment = var.environment
  label_order = ["name"]
  tags        = module.labels.tags

  engine            = "aurora-postgresql"
  engine_version    = "16.4"
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  performance_insights_enabled = true
}
