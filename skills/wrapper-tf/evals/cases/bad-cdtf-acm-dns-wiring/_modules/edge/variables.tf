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

variable "domain_name" {
  type        = string
  description = "Apex domain for the hosted zone and certificate."
}

variable "certificate_transparency_logging" {
  type        = bool
  description = "Whether to enable CT logging on the issued certificate."
  default     = true
}
