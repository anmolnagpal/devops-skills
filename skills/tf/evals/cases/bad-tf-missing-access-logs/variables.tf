variable "region" {
  type        = string
  description = "AWS region for this environment."
}

variable "alb_security_group_id" {
  type        = string
  description = "Security group attached to the public ALB."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs the internet-facing ALB attaches to."
}
