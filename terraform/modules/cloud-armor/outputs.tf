/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Cloud Armor Module - Outputs
 */

output "policy_id" {
  description = "Security policy ID"
  value       = google_compute_security_policy.policy.id
}

output "policy_name" {
  description = "Security policy name"
  value       = google_compute_security_policy.policy.name
}

output "policy_self_link" {
  description = "Security policy self link (for use with backend services)"
  value       = google_compute_security_policy.policy.self_link
}

output "policy_fingerprint" {
  description = "Security policy fingerprint"
  value       = google_compute_security_policy.policy.fingerprint
}

output "owasp_rules_enabled" {
  description = "Whether OWASP rules are enabled"
  value       = var.enable_owasp_rules
}

output "rate_limiting_enabled" {
  description = "Whether rate limiting is enabled"
  value       = var.enable_rate_limiting
}

output "rate_limit_config" {
  description = "Rate limiting configuration"
  value = var.enable_rate_limiting ? {
    requests_per_interval = var.rate_limit_requests_per_interval
    interval_sec          = var.rate_limit_interval_sec
    ban_duration_sec      = var.rate_limit_ban_duration_sec
  } : null
}

output "blocked_countries" {
  description = "List of blocked countries"
  value       = var.blocked_countries
}

output "gke_backend_annotation" {
  description = "Annotation to add to GKE Ingress for Cloud Armor"
  value       = "cloud.google.com/backend-config: '{\"default\": \"${var.project_name}-backend-config-${var.environment}\"}'"
}

output "backend_config_yaml" {
  description = "BackendConfig YAML for GKE to attach Cloud Armor policy"
  value       = <<-EOT
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: ${var.project_name}-backend-config-${var.environment}
spec:
  securityPolicy:
    name: ${google_compute_security_policy.policy.name}
EOT
}
