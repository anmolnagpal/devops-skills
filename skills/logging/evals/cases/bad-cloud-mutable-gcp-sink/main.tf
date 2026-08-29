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
    prefix = "env/prod/audit-sink"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  tags = {
    name        = "acme-prod-audit-sink"
    environment = "prod"
    team        = "platform"
    managed_by  = "terraform"
  }
}

# Destination bucket for the project audit logs. It is unlocked and retains
# only 7 days, so the trail can be rewritten or aged out before an
# investigation reaches it — a mutable audit sink in a prod environment.
resource "google_logging_project_bucket_config" "audit" {
  project        = var.project_id
  location       = var.region
  bucket_id      = "acme-prod-audit-logs"
  retention_days = 7
  locked         = false
}
