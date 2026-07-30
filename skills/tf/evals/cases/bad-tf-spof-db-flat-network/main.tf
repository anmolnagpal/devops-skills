terraform {
  required_version = "~> 1.14"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.0" }
  }
  backend "s3" {
    bucket         = "acme-tfstate"
    key            = "env/prod/data.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "acme-tfstate-lock"
    encrypt        = true
  }
}

locals {
  tags = {
    Name        = "${var.client}-${var.environment}-data"
    Environment = var.environment
    Team        = "platform"
    ManagedBy   = "terraform"
  }
}

# Primary customer database for prod. One instance, no lifecycle guard.
resource "aws_db_instance" "primary" {
  identifier        = "${var.client}-${var.environment}-orders"
  engine            = "postgres"
  engine_version    = "16.4"
  instance_class    = "db.r7g.xlarge"
  allocated_storage = 500
  multi_az          = false
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn
  username          = var.db_username
  password          = var.db_password
  tags              = local.tags
}

# Every subnet identical: same route table, no public/private/data separation.
resource "aws_subnet" "flat" {
  count             = 3
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]
  tags              = local.tags
}

resource "aws_eks_node_group" "workers" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.client}-${var.environment}-workers"
  node_role_arn   = var.node_role_arn
  subnet_ids      = aws_subnet.flat[*].id
  capacity_type   = "ON_DEMAND"
  instance_types  = ["m7i.2xlarge"]

  scaling_config {
    desired_size = 6
    min_size     = 6
    max_size     = 6
  }

  tags = local.tags
}
