module "labels" {
  source      = "clouddrove/labels/aws"
  version     = "1.3.0"
  name        = var.name
  environment = var.environment
  label_order = ["name", "environment"]
}

module "aurora" {
  source  = "clouddrove/aurora/aws"
  version = "1.0.5"

  name        = module.labels.id
  environment = var.environment

  engine         = "aurora-postgresql"
  engine_version = "16.4"
  instance_class = "db.r7g.large"

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # wrapper-tf:ignore SEC-NET-002
  publicly_accessible = true

  performance_insights_enabled = true
}
