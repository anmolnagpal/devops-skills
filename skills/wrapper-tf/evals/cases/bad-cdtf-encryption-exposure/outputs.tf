output "alb_dns_name" {
  description = "Public ALB DNS name."
  value       = module.alb.dns_name
}
