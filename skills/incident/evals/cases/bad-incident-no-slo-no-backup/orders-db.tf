# The cluster the runbook's restore procedure depends on. No backup policy: no
# retention window set, and no AWS Backup plan or snapshot resource anywhere.
resource "aws_rds_cluster" "orders" {
  cluster_identifier = "prod-orders"
  engine             = "aurora-postgresql"
  engine_version     = "16.4"
  database_name      = "orders"
  storage_encrypted  = true
  kms_key_id         = var.kms_key_arn

  skip_final_snapshot = true

  tags = {
    Name        = "prod-orders"
    Environment = "prod"
    Team        = "commerce"
    ManagedBy   = "terraform"
  }
}
