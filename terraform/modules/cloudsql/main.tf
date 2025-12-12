/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Cloud SQL Module
 * Creates Cloud SQL PostgreSQL instance with High Availability
 */

# Random suffix for instance name (Cloud SQL names must be unique)
resource "random_id" "db_name_suffix" {
  byte_length = 4
}

# Cloud SQL Instance
resource "google_sql_database_instance" "primary" {
  name                = "${var.project_name}-db-${random_id.db_name_suffix.hex}"
  project             = var.project_id
  region              = var.region
  database_version    = var.database_version
  deletion_protection = var.deletion_protection

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    disk_autoresize   = var.disk_autoresize

    # IP Configuration - Private IP only
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_id
      enable_private_path_for_google_cloud_services = true
    }

    # Backup Configuration
    backup_configuration {
      enabled                        = var.backup_enabled
      start_time                     = var.backup_start_time
      location                       = var.backup_location
      point_in_time_recovery_enabled = var.point_in_time_recovery
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.retained_backups
        retention_unit   = "COUNT"
      }
    }

    # Maintenance Window
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_update_track
    }

    # Database Flags
    dynamic "database_flags" {
      for_each = var.database_flags
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    # Insights (Query Insights)
    insights_config {
      query_insights_enabled  = var.query_insights_enabled
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    user_labels = {
      environment = var.environment
      project     = var.project_name
      managed_by  = "terraform"
    }
  }

  depends_on = [var.private_vpc_connection]
}

# Read Replica (for production)
resource "google_sql_database_instance" "read_replica" {
  count = var.create_read_replica ? 1 : 0

  name                 = "${var.project_name}-db-replica-${random_id.db_name_suffix.hex}"
  project              = var.project_id
  region               = var.replica_region != "" ? var.replica_region : var.region
  database_version     = var.database_version
  master_instance_name = google_sql_database_instance.primary.name
  deletion_protection  = var.deletion_protection

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.replica_tier != "" ? var.replica_tier : var.tier
    availability_type = "ZONAL"
    disk_size         = var.disk_size
    disk_type         = var.disk_type
    disk_autoresize   = var.disk_autoresize

    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = var.vpc_id
      enable_private_path_for_google_cloud_services = true
    }

    insights_config {
      query_insights_enabled  = var.query_insights_enabled
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    user_labels = {
      environment = var.environment
      project     = var.project_name
      role        = "replica"
      managed_by  = "terraform"
    }
  }
}

# Default Database
resource "google_sql_database" "default" {
  name     = var.database_name
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
  charset  = "UTF8"
}

# Additional Databases
resource "google_sql_database" "additional" {
  for_each = toset(var.additional_databases)

  name     = each.value
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
  charset  = "UTF8"
}

# Random password for default user
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Default User
resource "google_sql_user" "default" {
  name     = var.database_user
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
  password = random_password.db_password.result
}

# Additional Users
resource "random_password" "additional_user_password" {
  for_each = toset(var.additional_users)

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_sql_user" "additional" {
  for_each = toset(var.additional_users)

  name     = each.value
  project  = var.project_id
  instance = google_sql_database_instance.primary.name
  password = random_password.additional_user_password[each.key].result
}

# Store password in Secret Manager
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.project_name}-db-password"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Store connection string in Secret Manager
resource "google_secret_manager_secret" "db_connection_string" {
  secret_id = "${var.project_name}-db-connection"
  project   = var.project_id

  replication {
    auto {}
  }

  labels = {
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "google_secret_manager_secret_version" "db_connection_string" {
  secret      = google_secret_manager_secret.db_connection_string.id
  secret_data = "postgresql://${var.database_user}:${random_password.db_password.result}@${google_sql_database_instance.primary.private_ip_address}:5432/${var.database_name}"
}
