# Prod log groups for the payments platform.
resource "aws_cloudwatch_log_group" "app" {
  name = "/aws/eks/prod-payments/checkout-api"
  tags = local.tags
}

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/eks/prod-payments/checkout-api-audit"
  retention_in_days = 0
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "debug" {
  name              = "/aws/eks/prod-payments/checkout-api-debug"
  retention_in_days = 7
  tags              = local.tags
}
