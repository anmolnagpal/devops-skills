variable "resource_group_name" {
  type        = string
  description = "Name of the resource group holding the AKS cluster."
}

variable "location" {
  type        = string
  description = "Azure region for this environment."
}
