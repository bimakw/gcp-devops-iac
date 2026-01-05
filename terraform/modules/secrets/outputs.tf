/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Secret Manager Module - Outputs
 */

output "secret_ids" {
  description = "Map of secret IDs"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.secret_id }
}

output "secret_names" {
  description = "Map of secret names (full resource names)"
  value       = { for k, v in google_secret_manager_secret.secrets : k => v.name }
}

output "secret_version_ids" {
  description = "Map of secret version IDs"
  value       = { for k, v in google_secret_manager_secret_version.versions : k => v.id }
}

# Default secrets outputs
output "jwt_secret_id" {
  description = "JWT Secret ID"
  value       = var.create_default_secrets ? google_secret_manager_secret.app_secrets["jwt-secret"].secret_id : null
}

output "api_key_secret_id" {
  description = "API Key Secret ID"
  value       = var.create_default_secrets ? google_secret_manager_secret.app_secrets["api-key"].secret_id : null
}

output "encryption_key_secret_id" {
  description = "Encryption Key Secret ID"
  value       = var.create_default_secrets ? google_secret_manager_secret.app_secrets["encryption-key"].secret_id : null
}

# Service Account outputs
output "secret_accessor_sa_email" {
  description = "Secret Accessor Service Account Email"
  value       = var.create_secret_accessor_sa ? google_service_account.secret_accessor[0].email : null
}

output "secret_accessor_sa_name" {
  description = "Secret Accessor Service Account Name"
  value       = var.create_secret_accessor_sa ? google_service_account.secret_accessor[0].name : null
}

# Helper output for mounting secrets in GKE
output "gke_secret_store_config" {
  description = "Configuration for GKE Secret Store CSI Driver"
  value = var.create_default_secrets ? {
    provider = "gcp"
    secrets = {
      jwt_secret = {
        resourceName = "projects/${var.project_id}/secrets/${var.project_name}-jwt-secret/versions/latest"
        key          = "jwt-secret"
      }
      api_key = {
        resourceName = "projects/${var.project_id}/secrets/${var.project_name}-api-key/versions/latest"
        key          = "api-key"
      }
      encryption_key = {
        resourceName = "projects/${var.project_id}/secrets/${var.project_name}-encryption-key/versions/latest"
        key          = "encryption-key"
      }
    }
  } : null
}
