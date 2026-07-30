variable "region" {
  type        = string
  description = "AWS region for this environment."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the platform VPC."
}

variable "audit_log_bucket" {
  type        = string
  description = "Name of the bucket receiving CloudTrail events."
}

variable "flow_log_bucket_arn" {
  type        = string
  description = "ARN of the bucket receiving VPC flow logs."
}
