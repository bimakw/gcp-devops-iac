/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Cloud Build Module - Variables
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

# GitHub Configuration
variable "github_owner" {
  description = "GitHub repository owner/organization"
  type        = string
  default     = ""
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID (for Cloud Build GitHub App)"
  type        = string
  default     = ""
}

variable "github_oauth_token_secret" {
  description = "Secret Manager secret version for GitHub OAuth token"
  type        = string
  default     = ""
}

# Build Configuration Files
variable "cloudbuild_filename" {
  description = "Path to cloudbuild.yaml file"
  type        = string
  default     = "cloudbuild.yaml"
}

variable "cloudbuild_pr_filename" {
  description = "Path to cloudbuild file for pull requests"
  type        = string
  default     = "cloudbuild-pr.yaml"
}

variable "cloudbuild_release_filename" {
  description = "Path to cloudbuild file for releases"
  type        = string
  default     = "cloudbuild-release.yaml"
}

# Trigger Configuration
variable "create_push_trigger" {
  description = "Create push to main trigger"
  type        = bool
  default     = true
}

variable "create_develop_trigger" {
  description = "Create push to develop trigger"
  type        = bool
  default     = true
}

variable "create_pr_trigger" {
  description = "Create pull request trigger"
  type        = bool
  default     = true
}

variable "create_tag_trigger" {
  description = "Create tag/release trigger"
  type        = bool
  default     = true
}

variable "create_manual_trigger" {
  description = "Create manual trigger"
  type        = bool
  default     = false
}

# Build Substitutions
variable "artifact_registry_url" {
  description = "Artifact Registry URL"
  type        = string
  default     = ""
}

variable "gke_cluster_name" {
  description = "GKE cluster name for deployments"
  type        = string
  default     = ""
}

variable "additional_substitutions" {
  description = "Additional substitution variables"
  type        = map(string)
  default     = {}
}
