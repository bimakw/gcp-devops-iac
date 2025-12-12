/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Monitoring Module - Variables
 */

# Project Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast1"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# Notification Channels
variable "alert_email_addresses" {
  description = "Email addresses for alert notifications"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
}

variable "slack_channel_name" {
  description = "Slack channel name"
  type        = string
  default     = "#alerts"
}

variable "slack_auth_token" {
  description = "Slack auth token"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_service_key" {
  description = "PagerDuty service key"
  type        = string
  default     = ""
  sensitive   = true
}

# GKE Alert Thresholds
variable "create_gke_alerts" {
  description = "Create GKE alert policies"
  type        = bool
  default     = true
}

variable "gke_cpu_threshold" {
  description = "GKE CPU alert threshold percentage"
  type        = number
  default     = 80
}

variable "gke_memory_threshold" {
  description = "GKE Memory alert threshold percentage"
  type        = number
  default     = 80
}

variable "pod_restart_threshold" {
  description = "Pod restart count threshold"
  type        = number
  default     = 3
}

# Cloud SQL Alert Thresholds
variable "create_cloudsql_alerts" {
  description = "Create Cloud SQL alert policies"
  type        = bool
  default     = true
}

variable "cloudsql_cpu_threshold" {
  description = "Cloud SQL CPU alert threshold percentage"
  type        = number
  default     = 80
}

variable "cloudsql_disk_threshold" {
  description = "Cloud SQL disk alert threshold percentage"
  type        = number
  default     = 80
}

variable "cloudsql_connection_threshold" {
  description = "Cloud SQL connection count threshold"
  type        = number
  default     = 100
}

# Uptime Checks
variable "uptime_check_urls" {
  description = "Map of uptime check configurations"
  type = map(object({
    host          = string
    path          = string
    port          = number
    use_ssl       = bool
    validate_ssl  = bool
    content_match = string
  }))
  default = {}
}

# Log Sinks
variable "create_bigquery_sink" {
  description = "Create BigQuery log sink"
  type        = bool
  default     = false
}

variable "bigquery_dataset" {
  description = "BigQuery dataset name for logs"
  type        = string
  default     = "application_logs"
}

variable "bigquery_sink_filter" {
  description = "Filter for BigQuery log sink"
  type        = string
  default     = "severity >= WARNING"
}

variable "create_storage_sink" {
  description = "Create Cloud Storage log sink"
  type        = bool
  default     = false
}

variable "log_bucket_name" {
  description = "Cloud Storage bucket name for logs"
  type        = string
  default     = ""
}

variable "storage_sink_filter" {
  description = "Filter for Cloud Storage log sink"
  type        = string
  default     = "severity >= ERROR"
}

variable "log_retention_days" {
  description = "Number of days to retain logs in Cloud Storage"
  type        = number
  default     = 365
}
