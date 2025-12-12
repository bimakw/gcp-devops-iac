/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Development Environment Configuration
 */

module "infrastructure" {
  source = "../../"

  project_id   = var.project_id
  project_name = var.project_name
  region       = var.region
  environment  = "dev"

  # Networking - smaller ranges for dev
  public_subnet_cidr  = "10.0.1.0/24"
  private_subnet_cidr = "10.0.2.0/24"
  pods_cidr           = "10.1.0.0/16"
  services_cidr       = "10.2.0.0/16"

  # GKE - minimal for dev
  gke_deletion_protection     = false
  gke_enable_private_endpoint = false
  gke_machine_type            = "e2-standard-2"
  gke_min_nodes               = 1
  gke_max_nodes               = 3
  gke_create_spot_pool        = true

  # Cloud SQL - minimal for dev
  cloudsql_tier                = "db-f1-micro"
  cloudsql_availability_type   = "ZONAL"
  cloudsql_disk_size           = 10
  cloudsql_deletion_protection = false
  cloudsql_create_read_replica = false

  # Monitoring - basic
  create_monitoring_alerts = false
  alert_email_addresses    = var.alert_emails

  # CI/CD
  github_owner              = var.github_owner
  github_repo_name          = var.github_repo_name
  create_cloudbuild_triggers = var.enable_cloudbuild
}
