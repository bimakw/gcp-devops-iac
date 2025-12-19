/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Cloud Armor Module - Variables
 */

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

# OWASP Rules Configuration
variable "enable_owasp_rules" {
  description = "Enable OWASP ModSecurity Core Rule Set"
  type        = bool
  default     = true
}

variable "owasp_action" {
  description = "Action for OWASP rules (deny(403) or allow for logging only)"
  type        = string
  default     = "deny(403)"

  validation {
    condition     = can(regex("^(deny\\(\\d+\\)|allow)$", var.owasp_action))
    error_message = "OWASP action must be 'deny(STATUS_CODE)' or 'allow'."
  }
}

# Rate Limiting Configuration
variable "enable_rate_limiting" {
  description = "Enable rate limiting"
  type        = bool
  default     = true
}

variable "rate_limit_requests_per_interval" {
  description = "Number of requests allowed per interval"
  type        = number
  default     = 100
}

variable "rate_limit_interval_sec" {
  description = "Rate limit interval in seconds"
  type        = number
  default     = 60

  validation {
    condition     = contains([60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600], var.rate_limit_interval_sec)
    error_message = "Interval must be one of: 60, 120, 180, 240, 300, 600, 900, 1200, 1800, 2700, 3600."
  }
}

variable "rate_limit_ban_duration_sec" {
  description = "Duration to ban IPs that exceed rate limit (in seconds)"
  type        = number
  default     = 600
}

variable "rate_limit_ban_threshold_count" {
  description = "Number of rate limit violations before banning"
  type        = number
  default     = 5
}

variable "rate_limit_ban_threshold_interval_sec" {
  description = "Interval for counting rate limit violations"
  type        = number
  default     = 120
}

# Geo-blocking Configuration
variable "blocked_countries" {
  description = "List of country codes to block (ISO 3166-1 alpha-2)"
  type        = list(string)
  default     = []
}

# IP Lists
variable "allowlist_ips" {
  description = "List of trusted IP ranges to always allow"
  type        = list(string)
  default     = []
}

variable "blocklist_ips" {
  description = "List of IP ranges to always block"
  type        = list(string)
  default     = []
}

# Adaptive Protection (Cloud Armor Plus required)
variable "enable_adaptive_protection" {
  description = "Enable adaptive protection (requires Cloud Armor Plus subscription)"
  type        = bool
  default     = false
}

# Labels
variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}
