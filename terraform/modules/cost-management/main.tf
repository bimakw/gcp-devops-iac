/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Cost Management Module
 * Budget alerts, cost allocation, and optimization
 */

# Pub/Sub topic for budget alerts
resource "google_pubsub_topic" "budget_alerts" {
  name    = "${var.project_name}-budget-alerts"
  project = var.project_id

  labels = merge(var.labels, {
    component = "cost-management"
  })
}

# Pub/Sub subscription for processing alerts
resource "google_pubsub_subscription" "budget_alerts" {
  name    = "${var.project_name}-budget-alerts-sub"
  project = var.project_id
  topic   = google_pubsub_topic.budget_alerts.name

  # Message retention
  message_retention_duration = "604800s" # 7 days

  # Acknowledgement deadline
  ack_deadline_seconds = 60

  # Expiration policy (never expire)
  expiration_policy {
    ttl = ""
  }

  labels = merge(var.labels, {
    component = "cost-management"
  })
}

# Budget for the project
resource "google_billing_budget" "project_budget" {
  billing_account = var.billing_account_id
  display_name    = "${var.project_name}-${var.environment}-budget"

  budget_filter {
    projects               = ["projects/${var.project_id}"]
    credit_types_treatment = "INCLUDE_ALL_CREDITS"
  }

  amount {
    specified_amount {
      currency_code = var.currency_code
      units         = var.monthly_budget_amount
    }
  }

  # Threshold rules for alerts
  dynamic "threshold_rules" {
    for_each = var.budget_alert_thresholds
    content {
      threshold_percent = threshold_rules.value / 100
      spend_basis       = "CURRENT_SPEND"
    }
  }

  # Pub/Sub notification
  all_updates_rule {
    pubsub_topic                     = google_pubsub_topic.budget_alerts.id
    schema_version                   = "1.0"
    monitoring_notification_channels = var.notification_channels
  }
}

# Per-service budgets (optional)
resource "google_billing_budget" "service_budgets" {
  for_each = var.service_budgets

  billing_account = var.billing_account_id
  display_name    = "${var.project_name}-${each.key}-budget"

  budget_filter {
    projects = ["projects/${var.project_id}"]
    services = [each.value.service_id]
  }

  amount {
    specified_amount {
      currency_code = var.currency_code
      units         = each.value.amount
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.8
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    pubsub_topic   = google_pubsub_topic.budget_alerts.id
    schema_version = "1.0"
  }
}

# BigQuery dataset for cost export
resource "google_bigquery_dataset" "billing_export" {
  count = var.enable_billing_export ? 1 : 0

  dataset_id  = "billing_export"
  project     = var.project_id
  location    = var.region
  description = "GCP Billing export data for cost analysis"

  labels = merge(var.labels, {
    component = "cost-management"
  })

  # 90 days default table expiration
  default_table_expiration_ms = 7776000000

  access {
    role          = "OWNER"
    special_group = "projectOwners"
  }

  access {
    role          = "READER"
    special_group = "projectReaders"
  }
}

# Cloud Function for budget alert processing (optional)
resource "google_storage_bucket" "functions_source" {
  count = var.enable_slack_notifications ? 1 : 0

  name                        = "${var.project_id}-budget-functions"
  project                     = var.project_id
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }

  labels = merge(var.labels, {
    component = "cost-management"
  })
}

# Service account for budget notifications
resource "google_service_account" "budget_notifier" {
  count = var.enable_slack_notifications ? 1 : 0

  account_id   = "${var.project_name}-budget-notifier"
  project      = var.project_id
  display_name = "Budget Alert Notifier"
  description  = "Service account for processing budget alerts"
}

# Grant Pub/Sub subscriber role
resource "google_pubsub_subscription_iam_member" "budget_subscriber" {
  count = var.enable_slack_notifications ? 1 : 0

  project      = var.project_id
  subscription = google_pubsub_subscription.budget_alerts.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.budget_notifier[0].email}"
}

# Resource labels for cost allocation
locals {
  cost_allocation_labels = {
    environment = var.environment
    project     = var.project_name
    cost_center = var.cost_center
    team        = var.team
    managed_by  = "terraform"
  }
}

# Monitoring alert policy for billing anomalies
resource "google_monitoring_alert_policy" "billing_anomaly" {
  count = var.enable_anomaly_detection ? 1 : 0

  project      = var.project_id
  display_name = "Billing Anomaly Detection"
  combiner     = "OR"

  conditions {
    display_name = "Spending Rate Anomaly"

    condition_threshold {
      filter          = "resource.type=\"global\" AND metric.type=\"billing.googleapis.com/billing_account/cost\""
      comparison      = "COMPARISON_GT"
      duration        = "3600s"
      threshold_value = var.anomaly_threshold_percent

      aggregations {
        alignment_period     = "86400s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = var.notification_channels

  alert_strategy {
    auto_close = "86400s"
  }

  documentation {
    content   = "Billing anomaly detected. Spending rate has exceeded ${var.anomaly_threshold_percent}% of normal."
    mime_type = "text/markdown"
  }

  user_labels = local.cost_allocation_labels
}

# Recommender configuration for cost optimization
resource "google_project_service" "recommender" {
  project = var.project_id
  service = "recommender.googleapis.com"

  disable_on_destroy = false
}
