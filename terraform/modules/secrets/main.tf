/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Secret Manager Module
 * Creates and manages secrets in Google Secret Manager
 */

# Create secrets from map
resource "google_secret_manager_secret" "secrets" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = "${var.project_name}-${each.key}"

  replication {
    auto {}
  }

  labels = merge(
    {
      environment = var.environment
      project     = var.project_name
      managed_by  = "terraform"
    },
    each.value.labels
  )

  # Rotation configuration (if specified)
  dynamic "rotation" {
    for_each = each.value.rotation_period != "" ? [1] : []
    content {
      rotation_period    = each.value.rotation_period
      next_rotation_time = each.value.next_rotation_time
    }
  }

  # Expiration (if specified)
  dynamic "topics" {
    for_each = each.value.pubsub_topic != "" ? [1] : []
    content {
      name = each.value.pubsub_topic
    }
  }
}

# Create secret versions
resource "google_secret_manager_secret_version" "versions" {
  for_each = { for k, v in var.secrets : k => v if v.secret_data != "" }

  secret      = google_secret_manager_secret.secrets[each.key].id
  secret_data = each.value.secret_data

  depends_on = [google_secret_manager_secret.secrets]
}

# IAM bindings for GKE workload identity
resource "google_secret_manager_secret_iam_member" "workload_identity" {
  for_each = { for item in flatten([
    for secret_key, secret_value in var.secrets : [
      for sa in secret_value.accessor_service_accounts : {
        secret_key      = secret_key
        service_account = sa
      }
    ]
  ]) : "${item.secret_key}-${item.service_account}" => item }

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.value.secret_key].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.service_account}"
}

# Default application secrets
resource "google_secret_manager_secret" "app_secrets" {
  for_each = var.create_default_secrets ? toset(["jwt-secret", "api-key", "encryption-key"]) : toset([])

  project   = var.project_id
  secret_id = "${var.project_name}-${each.value}"

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    project     = var.project_name
    type        = "application"
    managed_by  = "terraform"
  }
}

# Generate random values for default secrets
resource "random_password" "jwt_secret" {
  count = var.create_default_secrets ? 1 : 0

  length           = 64
  special          = true
  override_special = "!@#$%^&*()_+-=[]{}|;:,.<>?"
}

resource "random_password" "api_key" {
  count = var.create_default_secrets ? 1 : 0

  length  = 32
  special = false
}

resource "random_password" "encryption_key" {
  count = var.create_default_secrets ? 1 : 0

  length  = 32
  special = false
}

# Secret versions for default secrets
resource "google_secret_manager_secret_version" "jwt_secret" {
  count = var.create_default_secrets ? 1 : 0

  secret      = google_secret_manager_secret.app_secrets["jwt-secret"].id
  secret_data = random_password.jwt_secret[0].result
}

resource "google_secret_manager_secret_version" "api_key" {
  count = var.create_default_secrets ? 1 : 0

  secret      = google_secret_manager_secret.app_secrets["api-key"].id
  secret_data = random_password.api_key[0].result
}

resource "google_secret_manager_secret_version" "encryption_key" {
  count = var.create_default_secrets ? 1 : 0

  secret      = google_secret_manager_secret.app_secrets["encryption-key"].id
  secret_data = random_password.encryption_key[0].result
}

# Grant access to default secrets for specified service accounts
resource "google_secret_manager_secret_iam_member" "default_secrets_access" {
  for_each = { for item in flatten([
    for secret in(var.create_default_secrets ? ["jwt-secret", "api-key", "encryption-key"] : []) : [
      for sa in var.default_secret_accessors : {
        secret          = secret
        service_account = sa
      }
    ]
  ]) : "${item.secret}-${item.service_account}" => item }

  project   = var.project_id
  secret_id = google_secret_manager_secret.app_secrets[each.value.secret].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.service_account}"
}

# Service Account for accessing secrets from GKE
resource "google_service_account" "secret_accessor" {
  count = var.create_secret_accessor_sa ? 1 : 0

  account_id   = "${var.project_name}-secret-accessor"
  project      = var.project_id
  display_name = "Secret Accessor Service Account"
  description  = "Service account for accessing secrets from GKE workloads"
}

# Workload Identity binding
resource "google_service_account_iam_member" "workload_identity_binding" {
  count = var.create_secret_accessor_sa && var.gke_namespace != "" ? 1 : 0

  service_account_id = google_service_account.secret_accessor[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.gke_namespace}/${var.gke_service_account_name}]"
}

# Grant secret accessor role to the SA
resource "google_project_iam_member" "secret_accessor_role" {
  count = var.create_secret_accessor_sa ? 1 : 0

  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.secret_accessor[0].email}"
}
