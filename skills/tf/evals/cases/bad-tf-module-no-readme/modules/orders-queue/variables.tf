variable "name" {
  type        = string
  description = "Queue name."
}

variable "retention_seconds" {
  type        = number
  description = "How long a message is retained before being dropped."
}

variable "visibility_timeout" {
  type        = number
  description = "Seconds a consumer holds a message before it reappears."
}

variable "kms_key_id" {
  type        = string
  description = "KMS key for queue encryption."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to both queues."
}
