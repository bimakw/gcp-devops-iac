/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GKE Module - Variables
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

# Network Configuration
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for GKE nodes"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
}

variable "services_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
}

variable "private_vpc_connection" {
  description = "Private VPC connection dependency"
  type        = string
  default     = ""
}

# Cluster Configuration
variable "node_locations" {
  description = "List of zones for node placement"
  type        = list(string)
  default     = []
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint (no public IP for master)"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of authorized networks for master access"
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

# Cluster Features
variable "enable_network_policy" {
  description = "Enable Kubernetes network policy"
  type        = bool
  default     = true
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization"
  type        = bool
  default     = false
}

variable "enable_managed_prometheus" {
  description = "Enable GKE Managed Prometheus"
  type        = bool
  default     = true
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "REGULAR"
}

variable "maintenance_start_time" {
  description = "Maintenance window start time (UTC)"
  type        = string
  default     = "03:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

# Node Auto-Provisioning
variable "enable_node_auto_provisioning" {
  description = "Enable node auto-provisioning"
  type        = bool
  default     = false
}

variable "nap_min_cpu" {
  description = "Minimum CPU for node auto-provisioning"
  type        = number
  default     = 0
}

variable "nap_max_cpu" {
  description = "Maximum CPU for node auto-provisioning"
  type        = number
  default     = 100
}

variable "nap_min_memory" {
  description = "Minimum memory (GB) for node auto-provisioning"
  type        = number
  default     = 0
}

variable "nap_max_memory" {
  description = "Maximum memory (GB) for node auto-provisioning"
  type        = number
  default     = 400
}

# Service Account
variable "node_service_account" {
  description = "Service account for GKE nodes"
  type        = string
}

# Primary Node Pool
variable "primary_pool_machine_type" {
  description = "Machine type for primary node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "primary_pool_disk_size_gb" {
  description = "Disk size in GB for primary pool nodes"
  type        = number
  default     = 100
}

variable "primary_pool_disk_type" {
  description = "Disk type for primary pool nodes"
  type        = string
  default     = "pd-standard"
}

variable "primary_pool_initial_node_count" {
  description = "Initial node count per zone"
  type        = number
  default     = 1
}

variable "primary_pool_min_node_count" {
  description = "Minimum nodes per zone"
  type        = number
  default     = 1
}

variable "primary_pool_max_node_count" {
  description = "Maximum nodes per zone"
  type        = number
  default     = 5
}

variable "primary_pool_preemptible" {
  description = "Use preemptible VMs for primary pool"
  type        = bool
  default     = false
}

variable "primary_pool_spot" {
  description = "Use spot VMs for primary pool"
  type        = bool
  default     = false
}

# Spot Node Pool
variable "create_spot_pool" {
  description = "Create a spot/preemptible node pool"
  type        = bool
  default     = false
}

variable "spot_pool_machine_type" {
  description = "Machine type for spot node pool"
  type        = string
  default     = "e2-standard-2"
}

variable "spot_pool_disk_size_gb" {
  description = "Disk size in GB for spot pool nodes"
  type        = number
  default     = 50
}

variable "spot_pool_initial_node_count" {
  description = "Initial node count per zone for spot pool"
  type        = number
  default     = 0
}

variable "spot_pool_min_node_count" {
  description = "Minimum nodes per zone for spot pool"
  type        = number
  default     = 0
}

variable "spot_pool_max_node_count" {
  description = "Maximum nodes per zone for spot pool"
  type        = number
  default     = 10
}
