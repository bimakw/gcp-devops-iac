/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Secret Manager Module - Variables
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

# Secrets Configuration
variable "secrets" {
  description = "Map of secrets to create"
  type = map(object({
    secret_data               = string
    labels                    = map(string)
    rotation_period           = string
    next_rotation_time        = string
    pubsub_topic              = string
    accessor_service_accounts = list(string)
  }))
  default = {}
}

# Default Application Secrets
variable "create_default_secrets" {
  description = "Create default application secrets (jwt-secret, api-key, encryption-key)"
  type        = bool
  default     = true
}

variable "default_secret_accessors" {
  description = "Service accounts that can access default secrets"
  type        = list(string)
  default     = []
}

# Secret Accessor Service Account
variable "create_secret_accessor_sa" {
  description = "Create a dedicated service account for secret access"
  type        = bool
  default     = true
}

variable "gke_namespace" {
  description = "GKE namespace for workload identity binding"
  type        = string
  default     = "default"
}

variable "gke_service_account_name" {
  description = "Kubernetes service account name for workload identity"
  type        = string
  default     = "default"
}
