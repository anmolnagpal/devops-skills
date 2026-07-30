output "db_endpoint" {
  description = "Primary database writer endpoint."
  value       = aws_db_instance.primary.endpoint
}
