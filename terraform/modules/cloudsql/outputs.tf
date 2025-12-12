/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Cloud SQL Module - Outputs
 */

output "instance_name" {
  description = "Cloud SQL Instance Name"
  value       = google_sql_database_instance.primary.name
}

output "instance_connection_name" {
  description = "Cloud SQL Instance Connection Name"
  value       = google_sql_database_instance.primary.connection_name
}

output "private_ip_address" {
  description = "Private IP Address"
  value       = google_sql_database_instance.primary.private_ip_address
}

output "database_name" {
  description = "Default Database Name"
  value       = google_sql_database.default.name
}

output "database_user" {
  description = "Default Database User"
  value       = google_sql_user.default.name
}

output "database_password_secret_id" {
  description = "Secret Manager Secret ID for database password"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "connection_string_secret_id" {
  description = "Secret Manager Secret ID for connection string"
  value       = google_secret_manager_secret.db_connection_string.secret_id
}

output "replica_instance_name" {
  description = "Read Replica Instance Name"
  value       = var.create_read_replica ? google_sql_database_instance.read_replica[0].name : null
}

output "replica_private_ip_address" {
  description = "Read Replica Private IP Address"
  value       = var.create_read_replica ? google_sql_database_instance.read_replica[0].private_ip_address : null
}

# Connection strings for applications
output "connection_info" {
  description = "Connection information for applications"
  value = {
    host     = google_sql_database_instance.primary.private_ip_address
    port     = 5432
    database = var.database_name
    user     = var.database_user
  }
  sensitive = false
}
