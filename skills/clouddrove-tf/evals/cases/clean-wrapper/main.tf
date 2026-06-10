# Fixture: correct CloudDrove wrapper module. Should produce ZERO findings.
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

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

variable "client_name" {
  type        = string
  description = "Client slug — used as resource name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "repository_url" {
  type        = string
  description = "Source repository URL — applied as a tag."
}

variable "cost_center" {
  type        = string
  description = "Cost center code — applied as a tag."
}

module "waf" {
  source  = "clouddrove/waf/aws"
  version = "1.4.0"

  name        = "${local.np}-waf"
  environment = var.environment
  label_order = ["name"]
  tags        = module.labels.tags
}

output "waf_arn" {
  description = "WAF Web ACL ARN."
  value       = module.waf.arn
}
