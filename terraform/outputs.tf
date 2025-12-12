/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GCP DevOps Infrastructure - Outputs
 */

# Networking Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_name" {
  description = "VPC Name"
  value       = module.networking.vpc_name
}

output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = module.networking.private_subnet_id
}

# GKE Outputs
output "gke_cluster_name" {
  description = "GKE Cluster Name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_get_credentials_command" {
  description = "Command to get GKE credentials"
  value       = module.gke.get_credentials_command
}

# Cloud SQL Outputs
output "cloudsql_instance_name" {
  description = "Cloud SQL Instance Name"
  value       = module.cloudsql.instance_name
}

output "cloudsql_private_ip" {
  description = "Cloud SQL Private IP"
  value       = module.cloudsql.private_ip_address
}

output "cloudsql_connection_name" {
  description = "Cloud SQL Connection Name"
  value       = module.cloudsql.instance_connection_name
}

output "cloudsql_password_secret_id" {
  description = "Secret ID for Cloud SQL password"
  value       = module.cloudsql.database_password_secret_id
}

# Artifact Registry Outputs
output "docker_repository_url" {
  description = "Docker Repository URL"
  value       = module.artifact_registry.docker_repository_url
}

output "docker_auth_command" {
  description = "Command to authenticate Docker"
  value       = module.artifact_registry.docker_auth_command
}

# Cloud Build Outputs
output "cloudbuild_service_account" {
  description = "Cloud Build Service Account"
  value       = module.cloud_build.service_account_email
}

# Secrets Outputs
output "jwt_secret_id" {
  description = "JWT Secret ID"
  value       = module.secrets.jwt_secret_id
}

output "api_key_secret_id" {
  description = "API Key Secret ID"
  value       = module.secrets.api_key_secret_id
}

# Summary
output "summary" {
  description = "Infrastructure Summary"
  value = <<-EOT

    ============================================
    GCP DevOps Infrastructure - ${var.project_name}
    Environment: ${var.environment}
    ============================================

    GKE Cluster: ${module.gke.cluster_name}
    Region: ${var.region}

    To connect to GKE:
    ${module.gke.get_credentials_command}

    Docker Registry:
    ${module.artifact_registry.docker_repository_url}

    Authenticate Docker:
    ${module.artifact_registry.docker_auth_command}

    Cloud SQL:
    Instance: ${module.cloudsql.instance_name}
    Private IP: ${module.cloudsql.private_ip_address}

    ============================================
  EOT
}
