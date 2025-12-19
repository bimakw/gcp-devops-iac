/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Memorystore Module - Variables
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

variable "vpc_id" {
  description = "VPC network ID for private access"
  type        = string
}

variable "private_vpc_connection" {
  description = "Private VPC connection dependency"
  type        = any
}

# Redis Configuration
variable "tier" {
  description = "Redis tier: BASIC (no HA) or STANDARD_HA (with replica)"
  type        = string
  default     = "BASIC"

  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "Tier must be BASIC or STANDARD_HA."
  }
}

variable "memory_size_gb" {
  description = "Redis memory size in GB"
  type        = number
  default     = 1

  validation {
    condition     = var.memory_size_gb >= 1 && var.memory_size_gb <= 300
    error_message = "Memory size must be between 1 and 300 GB."
  }
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "REDIS_7_0"

  validation {
    condition     = contains(["REDIS_6_X", "REDIS_7_0"], var.redis_version)
    error_message = "Redis version must be REDIS_6_X or REDIS_7_0."
  }
}

variable "maxmemory_policy" {
  description = "Redis maxmemory eviction policy"
  type        = string
  default     = "allkeys-lru"

  validation {
    condition = contains([
      "noeviction",
      "allkeys-lru",
      "allkeys-lfu",
      "allkeys-random",
      "volatile-lru",
      "volatile-lfu",
      "volatile-random",
      "volatile-ttl"
    ], var.maxmemory_policy)
    error_message = "Invalid maxmemory policy."
  }
}

variable "enable_keyspace_notifications" {
  description = "Enable Redis keyspace notifications"
  type        = bool
  default     = false
}

# Security
variable "auth_enabled" {
  description = "Enable Redis AUTH"
  type        = bool
  default     = true
}

variable "enable_tls" {
  description = "Enable TLS for in-transit encryption"
  type        = bool
  default     = true
}

variable "secret_accessors" {
  description = "List of service account emails that can access Redis auth secret"
  type        = list(string)
  default     = []
}

# Maintenance
variable "maintenance_day" {
  description = "Day of week for maintenance window (MONDAY, TUESDAY, etc.)"
  type        = string
  default     = "SUNDAY"

  validation {
    condition = contains([
      "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY",
      "FRIDAY", "SATURDAY", "SUNDAY"
    ], var.maintenance_day)
    error_message = "Invalid day of week."
  }
}

variable "maintenance_hour" {
  description = "Hour (UTC) for maintenance window start (0-23)"
  type        = number
  default     = 2

  validation {
    condition     = var.maintenance_hour >= 0 && var.maintenance_hour <= 23
    error_message = "Maintenance hour must be between 0 and 23."
  }
}

# Labels
variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}
