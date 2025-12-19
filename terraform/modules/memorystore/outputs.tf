/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Memorystore Module - Outputs
 */

output "instance_id" {
  description = "Redis instance ID"
  value       = google_redis_instance.cache.id
}

output "instance_name" {
  description = "Redis instance name"
  value       = google_redis_instance.cache.name
}

output "host" {
  description = "Redis instance host IP"
  value       = google_redis_instance.cache.host
}

output "port" {
  description = "Redis instance port"
  value       = google_redis_instance.cache.port
}

output "current_location_id" {
  description = "Current location of the Redis instance"
  value       = google_redis_instance.cache.current_location_id
}

output "connection_string" {
  description = "Redis connection string (without auth)"
  value       = "${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
}

output "redis_version" {
  description = "Redis version"
  value       = google_redis_instance.cache.redis_version
}

output "memory_size_gb" {
  description = "Memory size in GB"
  value       = google_redis_instance.cache.memory_size_gb
}

output "tier" {
  description = "Redis tier (BASIC or STANDARD_HA)"
  value       = google_redis_instance.cache.tier
}

output "auth_enabled" {
  description = "Whether AUTH is enabled"
  value       = google_redis_instance.cache.auth_enabled
}

output "auth_string" {
  description = "Redis AUTH string (sensitive)"
  value       = google_redis_instance.cache.auth_string
  sensitive   = true
}

output "auth_secret_id" {
  description = "Secret Manager secret ID for Redis auth string"
  value       = var.auth_enabled ? google_secret_manager_secret.redis_auth[0].secret_id : null
}

output "transit_encryption_mode" {
  description = "TLS encryption mode"
  value       = google_redis_instance.cache.transit_encryption_mode
}

output "server_ca_certs" {
  description = "Server CA certificates for TLS"
  value       = google_redis_instance.cache.server_ca_certs
  sensitive   = true
}
