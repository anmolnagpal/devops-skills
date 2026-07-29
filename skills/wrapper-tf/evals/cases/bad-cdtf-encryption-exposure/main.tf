# _modules/platform/main.tf — prod platform stack: Aurora, ElastiCache, ALB, EKS.
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

  engine         = "aurora-postgresql"
  engine_version = "16.4"

  storage_encrypted = false

  performance_insights_enabled = false
}

module "elasticache" {
  source  = "clouddrove/elasticache/aws"
  version = "2.0.1"

  name        = "${local.np}-redis"
  environment = var.environment
  label_order = ["name"]
  tags        = module.labels.tags

  engine                     = "redis"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = false
}

module "alb" {
  source  = "clouddrove/alb/aws"
  version = "1.4.2"

  name        = "${local.np}-alb"
  environment = var.environment
  label_order = ["name"]
  tags        = module.labels.tags

  internal            = false
  http_enabled        = true
  https_enabled       = true
  http_tcp_listeners  = [{ port = 80, protocol = "HTTP" }]
  enable_https_redirect = false
}

module "eks" {
  source  = "clouddrove/eks/aws"
  version = "1.6.0"

  name        = "${local.np}-eks"
  environment = var.environment
  label_order = ["name"]
  tags        = module.labels.tags

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
}

output "aurora_master_password" {
  description = "Aurora master password, consumed by the app deployment pipeline."
  value       = module.aurora.master_password
}
