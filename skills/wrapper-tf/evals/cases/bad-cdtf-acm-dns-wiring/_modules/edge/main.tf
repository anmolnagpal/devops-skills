# _modules/edge/ — DNS + certificate wiring. No outputs.tf in this directory.
module "labels" {
  source         = "../labels"
  client_name    = var.client_name
  environment    = var.environment
  repository_url = var.repository_url
  cost_center    = var.cost_center
}

locals {
  # Hand-rolled prefix instead of module.labels.name_prefix, so this module's
  # naming drifts from every other module the moment the label convention changes.
  name_prefix = "${var.client_name}-${var.environment}"
}

module "dns" {
  source  = "clouddrove/route53-hostedzone/aws"
  version = "1.0.2"

  name        = "${local.name_prefix}-dns"
  environment = var.environment
  label_order = ["name"]
  tags        = module.labels.tags

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
}

module "acm" {
  source  = "clouddrove/acm/aws"
  version = "1.4.1"

  name        = "${local.name_prefix}-acm"
  environment = var.environment
  label_order = ["name"]
  tags        = module.labels.tags

  domain_name = var.domain_name
  zone_id     = "Z04SBGH1OQ8YKPGXPRJ7"

  enable_dns_validation = false
}
