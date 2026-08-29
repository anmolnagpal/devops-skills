variable "region" {
  type        = string
  description = "AWS region for this environment."
}

variable "eks_cluster_role_arn" {
  type        = string
  description = "ARN of the IAM role the EKS control plane assumes."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs the EKS control plane attaches to."
}
