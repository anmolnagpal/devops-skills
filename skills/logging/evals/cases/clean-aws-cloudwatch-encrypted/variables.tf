variable "region" {
  type        = string
  description = "AWS region for this environment."
}

variable "audit_log_kms_key_arn" {
  type        = string
  description = "ARN of the customer-managed KMS key encrypting the audit log group."
}
