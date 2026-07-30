output "bucket_id" {
  description = "Customer document bucket name."
  value       = aws_s3_bucket.customer_documents.id
}

output "vpc_id" {
  description = "Platform VPC identifier."
  value       = aws_vpc.main.id
}
