/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Monitoring Module - Outputs
 */

output "email_notification_channels" {
  description = "Email notification channel IDs"
  value       = { for k, v in google_monitoring_notification_channel.email : k => v.name }
}

output "slack_notification_channel" {
  description = "Slack notification channel ID"
  value       = var.slack_webhook_url != "" ? google_monitoring_notification_channel.slack[0].name : null
}

output "pagerduty_notification_channel" {
  description = "PagerDuty notification channel ID"
  value       = var.pagerduty_service_key != "" ? google_monitoring_notification_channel.pagerduty[0].name : null
}

output "gke_cpu_alert_policy" {
  description = "GKE CPU alert policy ID"
  value       = var.create_gke_alerts ? google_monitoring_alert_policy.gke_high_cpu[0].name : null
}

output "gke_memory_alert_policy" {
  description = "GKE Memory alert policy ID"
  value       = var.create_gke_alerts ? google_monitoring_alert_policy.gke_high_memory[0].name : null
}

output "pod_crash_loop_alert_policy" {
  description = "Pod crash loop alert policy ID"
  value       = var.create_gke_alerts ? google_monitoring_alert_policy.pod_crash_loop[0].name : null
}

output "cloudsql_cpu_alert_policy" {
  description = "Cloud SQL CPU alert policy ID"
  value       = var.create_cloudsql_alerts ? google_monitoring_alert_policy.cloudsql_cpu[0].name : null
}

output "cloudsql_disk_alert_policy" {
  description = "Cloud SQL disk alert policy ID"
  value       = var.create_cloudsql_alerts ? google_monitoring_alert_policy.cloudsql_disk[0].name : null
}

output "uptime_check_ids" {
  description = "Uptime check IDs"
  value       = { for k, v in google_monitoring_uptime_check_config.http : k => v.uptime_check_id }
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID for logs"
  value       = var.create_bigquery_sink ? google_bigquery_dataset.logs[0].dataset_id : null
}

output "log_bucket_name" {
  description = "Cloud Storage bucket name for logs"
  value       = var.create_storage_sink ? google_storage_bucket.logs[0].name : null
}
