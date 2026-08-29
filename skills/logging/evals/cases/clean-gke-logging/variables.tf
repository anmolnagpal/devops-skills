variable "project_id" {
  type        = string
  description = "GCP project ID that owns the GKE cluster, audit config, and log bucket."
}

variable "region" {
  type        = string
  description = "GCP region and log-bucket location for the platform resources."
}
