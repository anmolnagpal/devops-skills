variable "client_name" {
  type        = string
  description = "Client slug, used as the resource name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment."
}

variable "repository_url" {
  type        = string
  description = "Source repository URL, applied as a tag."
}

variable "cost_center" {
  type        = string
  description = "Cost center code, applied as a tag."
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for Aurora storage encryption."
}
