resource "aws_sqs_queue" "this" {
  name                       = var.name
  message_retention_seconds  = var.retention_seconds
  visibility_timeout_seconds = var.visibility_timeout
  kms_master_key_id          = var.kms_key_id
  tags                       = var.tags
}

resource "aws_sqs_queue" "dlq" {
  name              = "${var.name}-dlq"
  kms_master_key_id = var.kms_key_id
  tags              = var.tags
}
