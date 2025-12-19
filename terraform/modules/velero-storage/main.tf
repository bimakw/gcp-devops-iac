/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Velero Storage Module
 * GCS bucket for Velero backups
 */

# GCS Bucket for Velero backups
resource "google_storage_bucket" "velero_backup" {
  name     = "${var.project_id}-velero-backups"
  project  = var.project_id
  location = var.region

  # Storage class
  storage_class = var.storage_class

  # Enable versioning for backup safety
  versioning {
    enabled = true
  }

  # Lifecycle rules
  lifecycle_rule {
    condition {
      age = var.backup_retention_days
    }
    action {
      type = "Delete"
    }
  }

  # Move to nearline after 30 days
  dynamic "lifecycle_rule" {
    for_each = var.enable_lifecycle_transition ? [1] : []
    content {
      condition {
        age = 30
      }
      action {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
    }
  }

  # Move to coldline after 90 days
  dynamic "lifecycle_rule" {
    for_each = var.enable_lifecycle_transition ? [1] : []
    content {
      condition {
        age = 90
      }
      action {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
    }
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  # Labels
  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    component   = "disaster-recovery"
  })

  # Prevent accidental deletion
  force_destroy = var.force_destroy
}

# Service Account for Velero
resource "google_service_account" "velero" {
  account_id   = "${var.project_name}-velero"
  project      = var.project_id
  display_name = "Velero Backup Service Account"
  description  = "Service account for Velero Kubernetes backups"
}

# IAM for bucket access
resource "google_storage_bucket_iam_member" "velero_bucket" {
  bucket = google_storage_bucket.velero_backup.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.velero.email}"
}

# Compute API access for snapshots
resource "google_project_iam_member" "velero_compute" {
  project = var.project_id
  role    = "roles/compute.storageAdmin"
  member  = "serviceAccount:${google_service_account.velero.email}"
}

# IAM API access
resource "google_project_iam_member" "velero_iam" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.velero.email}"
}

# Workload Identity binding
resource "google_service_account_iam_member" "velero_workload_identity" {
  service_account_id = google_service_account.velero.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[velero/velero]"
}
