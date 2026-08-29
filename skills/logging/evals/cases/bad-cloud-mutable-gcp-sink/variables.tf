variable "project_id" {
  type        = string
  description = "GCP project ID that owns the audit-log bucket."
}

variable "region" {
  type        = string
  description = "GCP location for the log bucket."
}
