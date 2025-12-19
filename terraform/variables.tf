/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GCP DevOps Infrastructure - Variables
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
  default     = "dev"
}

# Networking
variable "public_subnet_cidr" {
  description = "CIDR range for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR range for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "pods_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "services_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.2.0.0/16"
}

# GKE Configuration
variable "gke_deletion_protection" {
  description = "Enable GKE deletion protection"
  type        = bool
  default     = true
}

variable "gke_enable_private_endpoint" {
  description = "Enable private endpoint for GKE master"
  type        = bool
  default     = false
}

variable "gke_master_authorized_networks" {
  description = "Authorized networks for GKE master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "All"
    }
  ]
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "gke_min_nodes" {
  description = "Minimum nodes per zone"
  type        = number
  default     = 1
}

variable "gke_max_nodes" {
  description = "Maximum nodes per zone"
  type        = number
  default     = 5
}

variable "gke_create_spot_pool" {
  description = "Create spot/preemptible node pool"
  type        = bool
  default     = false
}

# Cloud SQL Configuration
variable "cloudsql_tier" {
  description = "Cloud SQL instance tier"
  type        = string
  default     = "db-custom-2-4096"
}

variable "cloudsql_availability_type" {
  description = "Cloud SQL availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "cloudsql_disk_size" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 20
}

variable "cloudsql_deletion_protection" {
  description = "Enable Cloud SQL deletion protection"
  type        = bool
  default     = true
}

variable "cloudsql_create_read_replica" {
  description = "Create Cloud SQL read replica"
  type        = bool
  default     = false
}

variable "database_name" {
  description = "Default database name"
  type        = string
  default     = "app"
}

variable "database_user" {
  description = "Default database user"
  type        = string
  default     = "app"
}

# Artifact Registry
variable "create_helm_repo" {
  description = "Create Helm chart repository"
  type        = bool
  default     = false
}

# Cloud Build Configuration
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = ""
}

variable "github_repo_name" {
  description = "GitHub repository name"
  type        = string
  default     = ""
}

variable "create_cloudbuild_triggers" {
  description = "Create Cloud Build triggers"
  type        = bool
  default     = false
}

# Monitoring Configuration
variable "alert_email_addresses" {
  description = "Email addresses for alerts"
  type        = list(string)
  default     = []
}

variable "create_monitoring_alerts" {
  description = "Create monitoring alert policies"
  type        = bool
  default     = true
}

variable "uptime_check_urls" {
  description = "URLs for uptime checks"
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

# Secrets Configuration
variable "create_default_secrets" {
  description = "Create default application secrets"
  type        = bool
  default     = true
}

# Memorystore (Redis) Configuration
variable "create_redis" {
  description = "Create Memorystore Redis instance"
  type        = bool
  default     = false
}

variable "redis_tier" {
  description = "Redis tier (BASIC or STANDARD_HA)"
  type        = string
  default     = "BASIC"
}

variable "redis_memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "REDIS_7_0"
}

variable "redis_auth_enabled" {
  description = "Enable Redis AUTH"
  type        = bool
  default     = true
}

variable "redis_enable_tls" {
  description = "Enable TLS for Redis"
  type        = bool
  default     = true
}
