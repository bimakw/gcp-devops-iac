/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Cost Management Module - Outputs
 */

output "budget_id" {
  description = "Project budget ID"
  value       = google_billing_budget.project_budget.id
}

output "budget_name" {
  description = "Project budget display name"
  value       = google_billing_budget.project_budget.display_name
}

output "pubsub_topic" {
  description = "Pub/Sub topic for budget alerts"
  value       = google_pubsub_topic.budget_alerts.name
}

output "pubsub_topic_id" {
  description = "Pub/Sub topic ID for budget alerts"
  value       = google_pubsub_topic.budget_alerts.id
}

output "pubsub_subscription" {
  description = "Pub/Sub subscription for budget alerts"
  value       = google_pubsub_subscription.budget_alerts.name
}

output "billing_export_dataset" {
  description = "BigQuery dataset for billing export"
  value       = var.enable_billing_export ? google_bigquery_dataset.billing_export[0].dataset_id : null
}

output "service_budget_ids" {
  description = "Map of service budget IDs"
  value       = { for k, v in google_billing_budget.service_budgets : k => v.id }
}

output "cost_allocation_labels" {
  description = "Standard cost allocation labels"
  value       = local.cost_allocation_labels
}

output "grafana_dashboard_json" {
  description = "Grafana dashboard JSON for cost monitoring"
  value       = <<-EOT
{
  "dashboard": {
    "title": "GCP Cost Dashboard",
    "tags": ["cost", "billing", "gcp"],
    "panels": [
      {
        "title": "Monthly Spend vs Budget",
        "type": "gauge",
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
      },
      {
        "title": "Daily Costs Trend",
        "type": "timeseries",
        "gridPos": {"h": 8, "w": 12, "x": 6, "y": 0}
      },
      {
        "title": "Cost by Service",
        "type": "piechart",
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0}
      },
      {
        "title": "Cost by Environment",
        "type": "barchart",
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      },
      {
        "title": "Cost Anomalies",
        "type": "stat",
        "gridPos": {"h": 8, "w": 6, "x": 12, "y": 8}
      },
      {
        "title": "Budget Alerts",
        "type": "table",
        "gridPos": {"h": 8, "w": 6, "x": 18, "y": 8}
      }
    ]
  }
}
EOT
}

output "recommender_insights_query" {
  description = "gcloud command to get cost optimization recommendations"
  value       = <<-EOT
# Get compute optimization recommendations
gcloud recommender recommendations list \
  --project=${var.project_id} \
  --location=${var.region} \
  --recommender=google.compute.instance.MachineTypeRecommender

# Get idle resource recommendations
gcloud recommender recommendations list \
  --project=${var.project_id} \
  --location=${var.region} \
  --recommender=google.compute.instance.IdleResourceRecommender

# Get committed use discount recommendations
gcloud recommender recommendations list \
  --project=${var.project_id} \
  --location=global \
  --recommender=google.compute.commitment.UsageCommitmentRecommender
EOT
}
