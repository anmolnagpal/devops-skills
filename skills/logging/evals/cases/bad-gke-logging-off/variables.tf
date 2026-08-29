variable "project_id" {
  type        = string
  description = "GCP project ID that owns the GKE cluster and audit config."
}

variable "region" {
  type        = string
  description = "GCP region the GKE cluster is deployed into."
}
