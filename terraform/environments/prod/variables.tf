/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Production Environment - Variables
 */

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "myproject"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast1"
}

variable "master_authorized_networks" {
  description = "Authorized networks for GKE master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "enable_read_replica" {
  description = "Enable Cloud SQL read replica"
  type        = bool
  default     = true
}

variable "alert_emails" {
  description = "Email addresses for alerts"
  type        = list(string)
}

variable "github_owner" {
  description = "GitHub owner/organization"
  type        = string
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
}

variable "uptime_checks" {
  description = "Uptime check configurations"
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
