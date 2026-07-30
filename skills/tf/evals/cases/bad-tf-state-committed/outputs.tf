output "vpc_id" {
  description = "Staging VPC identifier."
  value       = aws_vpc.main.id
}
