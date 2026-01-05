/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Monitoring Module
 * Creates Cloud Monitoring dashboards, alerting policies, and log sinks
 */

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

# Notification Channel - Email
resource "google_monitoring_notification_channel" "email" {
  for_each = toset(var.alert_email_addresses)

  project      = var.project_id
  display_name = "Email - ${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }

  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Notification Channel - Slack (optional)
resource "google_monitoring_notification_channel" "slack" {
  count = var.slack_webhook_url != "" ? 1 : 0

  project      = var.project_id
  display_name = "Slack - ${var.project_name}"
  type         = "slack"

  labels = {
    channel_name = var.slack_channel_name
  }

  sensitive_labels {
    auth_token = var.slack_auth_token
  }

  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Notification Channel - PagerDuty (optional)
resource "google_monitoring_notification_channel" "pagerduty" {
  count = var.pagerduty_service_key != "" ? 1 : 0

  project      = var.project_id
  display_name = "PagerDuty - ${var.project_name}"
  type         = "pagerduty"

  labels = {
    service_key = var.pagerduty_service_key
  }

  user_labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Local for all notification channels
locals {
  notification_channels = concat(
    [for email in var.alert_email_addresses : google_monitoring_notification_channel.email[email].name],
    var.slack_webhook_url != "" ? [google_monitoring_notification_channel.slack[0].name] : [],
    var.pagerduty_service_key != "" ? [google_monitoring_notification_channel.pagerduty[0].name] : []
  )
}

# Alert Policy - High CPU Usage (GKE)
resource "google_monitoring_alert_policy" "gke_high_cpu" {
  count = var.create_gke_alerts ? 1 : 0

  project      = var.project_id
  display_name = "${var.project_name} - GKE High CPU Usage"
  combiner     = "OR"

  conditions {
    display_name = "GKE Node CPU > ${var.gke_cpu_threshold}%"

    condition_threshold {
      filter          = "resource.type = \"k8s_node\" AND metric.type = \"kubernetes.io/node/cpu/allocatable_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.gke_cpu_threshold / 100

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "GKE node CPU usage is above ${var.gke_cpu_threshold}%. Consider scaling up the node pool or optimizing workloads."
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "warning"
    environment = var.environment
  }
}

# Alert Policy - High Memory Usage (GKE)
resource "google_monitoring_alert_policy" "gke_high_memory" {
  count = var.create_gke_alerts ? 1 : 0

  project      = var.project_id
  display_name = "${var.project_name} - GKE High Memory Usage"
  combiner     = "OR"

  conditions {
    display_name = "GKE Node Memory > ${var.gke_memory_threshold}%"

    condition_threshold {
      filter          = "resource.type = \"k8s_node\" AND metric.type = \"kubernetes.io/node/memory/allocatable_utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.gke_memory_threshold / 100

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "GKE node memory usage is above ${var.gke_memory_threshold}%. Consider scaling up the node pool or optimizing workloads."
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "warning"
    environment = var.environment
  }
}

# Alert Policy - Pod Crash Loop
resource "google_monitoring_alert_policy" "pod_crash_loop" {
  count = var.create_gke_alerts ? 1 : 0

  project      = var.project_id
  display_name = "${var.project_name} - Pod Crash Loop"
  combiner     = "OR"

  conditions {
    display_name = "Pod restart count > ${var.pod_restart_threshold}"

    condition_threshold {
      filter          = "resource.type = \"k8s_container\" AND metric.type = \"kubernetes.io/container/restart_count\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.pod_restart_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.label.pod_name", "resource.label.namespace_name"]
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "A pod is experiencing crash loops. Check logs for error details: `kubectl logs <pod-name> -n <namespace> --previous`"
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "critical"
    environment = var.environment
  }
}

# Alert Policy - Cloud SQL CPU
resource "google_monitoring_alert_policy" "cloudsql_cpu" {
  count = var.create_cloudsql_alerts ? 1 : 0

  project      = var.project_id
  display_name = "${var.project_name} - Cloud SQL High CPU"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL CPU > ${var.cloudsql_cpu_threshold}%"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/cpu/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.cloudsql_cpu_threshold / 100

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Cloud SQL CPU utilization is above ${var.cloudsql_cpu_threshold}%. Consider upgrading the instance tier or optimizing queries."
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "warning"
    environment = var.environment
  }
}

# Alert Policy - Cloud SQL Disk Usage
resource "google_monitoring_alert_policy" "cloudsql_disk" {
  count = var.create_cloudsql_alerts ? 1 : 0

  project      = var.project_id
  display_name = "${var.project_name} - Cloud SQL High Disk Usage"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL Disk > ${var.cloudsql_disk_threshold}%"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/disk/utilization\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.cloudsql_disk_threshold / 100

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Cloud SQL disk utilization is above ${var.cloudsql_disk_threshold}%. Consider enabling auto-resize or cleaning up data."
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "critical"
    environment = var.environment
  }
}

# Alert Policy - Cloud SQL Connections
resource "google_monitoring_alert_policy" "cloudsql_connections" {
  count = var.create_cloudsql_alerts ? 1 : 0

  project      = var.project_id
  display_name = "${var.project_name} - Cloud SQL High Connections"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL Connections > ${var.cloudsql_connection_threshold}"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/postgresql/num_backends\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.cloudsql_connection_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Cloud SQL connection count is above ${var.cloudsql_connection_threshold}. Consider implementing connection pooling or increasing max_connections."
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "warning"
    environment = var.environment
  }
}

# Uptime Check - HTTP
resource "google_monitoring_uptime_check_config" "http" {
  for_each = var.uptime_check_urls

  project      = var.project_id
  display_name = each.key
  timeout      = "10s"
  period       = "60s"

  http_check {
    path           = each.value.path
    port           = each.value.port
    use_ssl        = each.value.use_ssl
    validate_ssl   = each.value.validate_ssl
    request_method = "GET"

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = each.value.host
    }
  }

  content_matchers {
    content = each.value.content_match
    matcher = "CONTAINS_STRING"
  }
}

# Alert Policy - Uptime Check Failed
resource "google_monitoring_alert_policy" "uptime_check_failed" {
  count = length(var.uptime_check_urls) > 0 ? 1 : 0

  project      = var.project_id
  display_name = "${var.project_name} - Uptime Check Failed"
  combiner     = "OR"

  conditions {
    display_name = "Uptime Check Failure"

    condition_threshold {
      filter          = "metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\" AND resource.type = \"uptime_url\""
      duration        = "60s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_FRACTION_TRUE"
        cross_series_reducer = "REDUCE_MIN"
        group_by_fields      = ["resource.label.host"]
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = local.notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "Uptime check failed. The service may be down or unreachable."
    mime_type = "text/markdown"
  }

  user_labels = {
    severity    = "critical"
    environment = var.environment
  }
}

# Log Sink - BigQuery (for long-term analytics)
resource "google_logging_project_sink" "bigquery" {
  count = var.create_bigquery_sink ? 1 : 0

  project     = var.project_id
  name        = "${var.project_name}-logs-bigquery"
  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${var.bigquery_dataset}"

  filter = var.bigquery_sink_filter

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# BigQuery Dataset for logs
resource "google_bigquery_dataset" "logs" {
  count = var.create_bigquery_sink ? 1 : 0

  project                    = var.project_id
  dataset_id                 = var.bigquery_dataset
  friendly_name              = "${var.project_name} Logs"
  description                = "Dataset for storing application logs"
  location                   = var.region
  delete_contents_on_destroy = false

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Grant write access to log sink
resource "google_bigquery_dataset_iam_member" "log_writer" {
  count = var.create_bigquery_sink ? 1 : 0

  project    = var.project_id
  dataset_id = google_bigquery_dataset.logs[0].dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.bigquery[0].writer_identity
}

# Log Sink - Cloud Storage (for archival)
resource "google_logging_project_sink" "storage" {
  count = var.create_storage_sink ? 1 : 0

  project     = var.project_id
  name        = "${var.project_name}-logs-storage"
  destination = "storage.googleapis.com/${var.log_bucket_name}"

  filter = var.storage_sink_filter

  unique_writer_identity = true
}

# Log bucket for archival
resource "google_storage_bucket" "logs" {
  count = var.create_storage_sink ? 1 : 0

  project       = var.project_id
  name          = var.log_bucket_name
  location      = var.region
  storage_class = "NEARLINE"

  lifecycle_rule {
    condition {
      age = var.log_retention_days
    }
    action {
      type = "Delete"
    }
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Grant write access to storage sink
resource "google_storage_bucket_iam_member" "log_writer" {
  count = var.create_storage_sink ? 1 : 0

  bucket = google_storage_bucket.logs[0].name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.storage[0].writer_identity
}
