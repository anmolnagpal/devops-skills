output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint."
  value       = module.aurora.endpoint
}
