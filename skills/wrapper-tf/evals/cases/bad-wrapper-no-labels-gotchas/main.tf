# Fixture: _modules/waf wrapper with pattern + module-gotcha violations. Not real.
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# missing: module "labels" + locals { np }

variable "client_name" {
  type = string
}

module "waf" {
  source = "clouddrove/waf/aws"

  name                = "my-hardcoded-waf"
  waf_scop            = "REGIONAL"
  web_acl_association = true
  allow_default_action = true
}

output "waf_arn" {
  value = module.waf.arn
}
