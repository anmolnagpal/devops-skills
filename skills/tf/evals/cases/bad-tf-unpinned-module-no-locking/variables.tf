variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "private_subnets" {
  type        = list(string)
  description = "Private subnet CIDRs, one per AZ."
}

variable "public_subnets" {
  type        = list(string)
  description = "Public subnet CIDRs, one per AZ."
}

variable "db_credentials_json" {
  type        = string
  description = "JSON blob of database credentials, sourced from CI."
  sensitive   = true
}
