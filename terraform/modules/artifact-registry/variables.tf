/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Artifact Registry Module - Variables
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

# Cleanup Policies
variable "enable_cleanup_policies" {
  description = "Enable cleanup policies for Docker repository"
  type        = bool
  default     = true
}

variable "keep_count" {
  description = "Number of recent versions to keep"
  type        = number
  default     = 10
}

variable "untagged_retention_days" {
  description = "Days to retain untagged images"
  type        = number
  default     = 7
}

# Additional Repositories
variable "create_npm_repo" {
  description = "Create NPM repository"
  type        = bool
  default     = false
}

variable "create_maven_repo" {
  description = "Create Maven repository"
  type        = bool
  default     = false
}

variable "create_python_repo" {
  description = "Create Python repository"
  type        = bool
  default     = false
}

variable "create_helm_repo" {
  description = "Create Helm charts repository"
  type        = bool
  default     = false
}

# Maven Configuration
variable "maven_allow_snapshot_overwrites" {
  description = "Allow overwriting snapshot versions in Maven repo"
  type        = bool
  default     = true
}

variable "maven_version_policy" {
  description = "Maven version policy (VERSION_POLICY_UNSPECIFIED, RELEASE, SNAPSHOT)"
  type        = string
  default     = "VERSION_POLICY_UNSPECIFIED"
}

# IAM Configuration
variable "gke_service_account" {
  description = "GKE node service account email"
  type        = string
  default     = ""
}

variable "cloudbuild_service_account" {
  description = "Cloud Build service account email"
  type        = string
  default     = ""
}

variable "additional_readers" {
  description = "Additional IAM members with read access"
  type        = list(string)
  default     = []
}

variable "additional_writers" {
  description = "Additional IAM members with write access"
  type        = list(string)
  default     = []
}
