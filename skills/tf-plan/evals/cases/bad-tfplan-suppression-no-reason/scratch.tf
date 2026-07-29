# tf-plan-skill:ignore TF-PLAN-001
resource "aws_ebs_volume" "ledger_archive" {
  availability_zone = "eu-west-1b"
  size              = 500
  encrypted         = true
  tags = {
    Environment = "prod"
    Team        = "payments"
    Purpose     = "settlement archive, 7-year retention"
  }
}
