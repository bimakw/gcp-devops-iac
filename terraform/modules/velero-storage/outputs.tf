/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Velero Storage Module - Outputs
 */

output "bucket_name" {
  description = "Velero backup bucket name"
  value       = google_storage_bucket.velero_backup.name
}

output "bucket_url" {
  description = "Velero backup bucket URL"
  value       = google_storage_bucket.velero_backup.url
}

output "service_account_email" {
  description = "Velero service account email"
  value       = google_service_account.velero.email
}

output "service_account_name" {
  description = "Velero service account name"
  value       = google_service_account.velero.name
}

output "velero_helm_values" {
  description = "Helm values for Velero installation"
  value       = <<-EOT
configuration:
  backupStorageLocation:
    - name: default
      provider: gcp
      bucket: ${google_storage_bucket.velero_backup.name}
      config:
        serviceAccount: ${google_service_account.velero.email}
  volumeSnapshotLocation:
    - name: default
      provider: gcp
      config:
        project: ${var.project_id}
        snapshotLocation: ${var.region}
serviceAccount:
  server:
    annotations:
      iam.gke.io/gcp-service-account: ${google_service_account.velero.email}
EOT
}
