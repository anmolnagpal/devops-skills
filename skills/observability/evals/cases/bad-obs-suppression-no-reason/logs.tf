resource "aws_cloudwatch_log_group" "app" {
  name = "/aws/eks/prod-payments/checkout-api"
  # observability-skill:ignore OBS-LOG-002
  tags = local.tags
}
