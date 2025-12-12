/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Cloud Build Module - Outputs
 */

output "service_account_email" {
  description = "Cloud Build Service Account Email"
  value       = google_service_account.cloudbuild.email
}

output "service_account_id" {
  description = "Cloud Build Service Account ID"
  value       = google_service_account.cloudbuild.id
}

output "push_main_trigger_id" {
  description = "Push to main trigger ID"
  value       = var.create_push_trigger ? google_cloudbuild_trigger.push_main[0].trigger_id : null
}

output "push_develop_trigger_id" {
  description = "Push to develop trigger ID"
  value       = var.create_develop_trigger ? google_cloudbuild_trigger.push_develop[0].trigger_id : null
}

output "pull_request_trigger_id" {
  description = "Pull request trigger ID"
  value       = var.create_pr_trigger ? google_cloudbuild_trigger.pull_request[0].trigger_id : null
}

output "tag_trigger_id" {
  description = "Tag/release trigger ID"
  value       = var.create_tag_trigger ? google_cloudbuild_trigger.tag[0].trigger_id : null
}

output "manual_trigger_id" {
  description = "Manual trigger ID"
  value       = var.create_manual_trigger ? google_cloudbuild_trigger.manual[0].trigger_id : null
}

output "github_connection_name" {
  description = "GitHub connection name"
  value       = var.github_app_installation_id != "" ? google_cloudbuildv2_connection.github[0].name : null
}
