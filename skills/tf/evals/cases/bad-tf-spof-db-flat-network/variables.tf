variable "client" {
  type        = string
  description = "Client slug used as the resource name prefix."
}

variable "environment" {
  type        = string
  description = "Deployment environment (dev/staging/prod)."
}

variable "vpc_id" {
  type        = string
  description = "VPC the subnets belong to."
}

variable "subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for the subnets, one per AZ."
}

variable "azs" {
  type        = list(string)
  description = "Availability zones to spread subnets across."
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key for database storage encryption."
}

variable "db_username" {
  type        = string
  description = "Database master username."
}

variable "db_password" {
  type        = string
  description = "Database master password, sourced from Secrets Manager."
  sensitive   = true
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster this node group joins."
}

variable "node_role_arn" {
  type        = string
  description = "IAM role ARN for the node group."
}
