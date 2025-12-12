/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Development Environment - Variables
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

variable "alert_emails" {
  description = "Email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "github_owner" {
  description = "GitHub owner/organization"
  type        = string
  default     = ""
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "enable_cloudbuild" {
  description = "Enable Cloud Build triggers"
  type        = bool
  default     = false
}
