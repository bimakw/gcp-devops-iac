/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Cost Management Module - Variables
 */

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "billing_account_id" {
  description = "GCP Billing Account ID"
  type        = string
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in specified currency"
  type        = number
}

variable "currency_code" {
  description = "Currency code for budget (e.g., USD, IDR)"
  type        = string
  default     = "USD"
}

variable "budget_alert_thresholds" {
  description = "List of threshold percentages for budget alerts"
  type        = list(number)
  default     = [50, 80, 90, 100, 110]
}

variable "notification_channels" {
  description = "List of notification channel IDs for alerts"
  type        = list(string)
  default     = []
}

variable "service_budgets" {
  description = "Map of per-service budgets"
  type = map(object({
    service_id = string
    amount     = number
  }))
  default = {}
}

variable "enable_billing_export" {
  description = "Enable BigQuery billing export"
  type        = bool
  default     = true
}

variable "enable_slack_notifications" {
  description = "Enable Slack notifications via Cloud Function"
  type        = bool
  default     = false
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_anomaly_detection" {
  description = "Enable billing anomaly detection alerts"
  type        = bool
  default     = true
}

variable "anomaly_threshold_percent" {
  description = "Threshold percentage for anomaly detection"
  type        = number
  default     = 150
}

variable "cost_center" {
  description = "Cost center for resource allocation"
  type        = string
  default     = "engineering"
}

variable "team" {
  description = "Team responsible for costs"
  type        = string
  default     = "platform"
}

variable "labels" {
  description = "Additional labels"
  type        = map(string)
  default     = {}
}
