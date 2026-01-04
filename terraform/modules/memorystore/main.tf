/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Memorystore (Redis) Module
 * Managed Redis instance for caching
 */

# Redis Instance
resource "google_redis_instance" "cache" {
  name           = "${var.project_name}-redis-${var.environment}"
  project        = var.project_id
  region         = var.region
  tier           = var.tier
  memory_size_gb = var.memory_size_gb

  # Redis version
  redis_version = var.redis_version

  # Display name
  display_name = "${var.project_name} Redis Cache (${var.environment})"

  # Network configuration
  authorized_network = var.vpc_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  # Redis configuration
  redis_configs = {
    maxmemory-policy       = var.maxmemory_policy
    notify-keyspace-events = var.enable_keyspace_notifications ? "Ex" : ""
  }

  # High Availability (for STANDARD_HA tier)
  dynamic "replica_count" {
    for_each = var.tier == "STANDARD_HA" ? [1] : []
    content {
      # HA tier automatically manages replicas
    }
  }

  # Maintenance window
  maintenance_policy {
    weekly_maintenance_window {
      day = var.maintenance_day
      start_time {
        hours   = var.maintenance_hour
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  # Authentication
  auth_enabled = var.auth_enabled

  # TLS
  transit_encryption_mode = var.enable_tls ? "SERVER_AUTHENTICATION" : "DISABLED"

  # Labels
  labels = merge(var.labels, {
    environment = var.environment
    managed_by  = "terraform"
    component   = "cache"
  })

  lifecycle {
    prevent_destroy = false
  }

  depends_on = [var.private_vpc_connection]
}

# Redis Auth String Secret (if auth is enabled)
resource "google_secret_manager_secret" "redis_auth" {
  count = var.auth_enabled ? 1 : 0

  secret_id = "${var.project_name}-redis-auth-${var.environment}"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    component   = "cache"
  }
}

resource "google_secret_manager_secret_version" "redis_auth" {
  count = var.auth_enabled ? 1 : 0

  secret      = google_secret_manager_secret.redis_auth[0].id
  secret_data = google_redis_instance.cache.auth_string
}

# IAM for secret access
resource "google_secret_manager_secret_iam_member" "redis_auth_access" {
  for_each = var.auth_enabled ? toset(var.secret_accessors) : []

  project   = var.project_id
  secret_id = google_secret_manager_secret.redis_auth[0].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value}"
}
