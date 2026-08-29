terraform {
  required_version = "~> 1.14"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
  backend "gcs" {
    bucket = "acme-tfstate"
    prefix = "env/prod/platform"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  tags = {
    name        = "acme-prod-platform"
    environment = "prod"
    team        = "platform"
    managed_by  = "terraform"
  }
}

# GKE cluster with Cloud Logging switched off entirely: no record of any
# control-plane API call or workload log leaves the cluster.
resource "google_container_cluster" "platform" {
  name     = "acme-prod-platform"
  location = var.region

  logging_service = "none"

  initial_node_count = 3

  resource_labels = local.tags
}

# No google_project_iam_audit_config anywhere in this root module, so Data
# Access audit logs (who read or wrote data) are never collected.
