variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the staging VPC."
}

variable "flow_log_bucket_arn" {
  type        = string
  description = "ARN of the bucket receiving VPC flow logs."
}
