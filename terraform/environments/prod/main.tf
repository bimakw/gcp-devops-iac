/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Production Environment Configuration
 */

module "infrastructure" {
  source = "../../"

  project_id   = var.project_id
  project_name = var.project_name
  region       = var.region
  environment  = "prod"

  # Networking
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  pods_cidr           = "10.1.0.0/16"
  services_cidr       = "10.2.0.0/16"

  # GKE - Production grade
  gke_deletion_protection        = true
  gke_enable_private_endpoint    = true
  gke_master_authorized_networks = var.master_authorized_networks
  gke_machine_type               = "e2-standard-4"
  gke_min_nodes                  = 2
  gke_max_nodes                  = 10
  gke_create_spot_pool           = true

  # Cloud SQL - HA for production
  cloudsql_tier                = "db-custom-4-8192"
  cloudsql_availability_type   = "REGIONAL"
  cloudsql_disk_size           = 50
  cloudsql_deletion_protection = true
  cloudsql_create_read_replica = var.enable_read_replica

  # Monitoring - Full
  create_monitoring_alerts = true
  alert_email_addresses    = var.alert_emails
  uptime_check_urls        = var.uptime_checks

  # CI/CD
  github_owner               = var.github_owner
  github_repo_name           = var.github_repo_name
  create_cloudbuild_triggers = true
}
