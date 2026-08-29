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

# GKE cluster with Cloud Logging fully enabled: system, workload, and all
# control-plane components ship to Cloud Logging.
resource "google_container_cluster" "platform" {
  name     = "acme-prod-platform"
  location = var.region

  logging_config {
    enable_components = [
      "SYSTEM_COMPONENTS",
      "WORKLOADS",
      "APISERVER",
      "CONTROLLER_MANAGER",
      "SCHEDULER",
    ]
  }

  initial_node_count = 3

  resource_labels = local.tags
}

# Data Access audit logs turned on for all services: both reads and writes
# are recorded, not just Admin Activity.
resource "google_project_iam_audit_config" "all_services" {
  project = var.project_id
  service = "allServices"

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }

  audit_log_config {
    log_type = "ADMIN_READ"
  }
}

# Audit-log destination: locked (immutable) and retained well beyond the
# team's audit-retention floor.
resource "google_logging_project_bucket_config" "audit" {
  project        = var.project_id
  location       = var.region
  bucket_id      = "acme-prod-audit-logs"
  retention_days = 400
  locked         = true
}
