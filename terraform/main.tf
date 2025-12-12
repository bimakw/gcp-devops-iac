/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * GCP DevOps Infrastructure - Main Configuration
 * This file orchestrates all Terraform modules
 */

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend configuration - uncomment and configure for remote state
  # backend "gcs" {
  #   bucket = "your-terraform-state-bucket"
  #   prefix = "terraform/state"
  # }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "servicenetworking.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

# Service Account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "${var.project_name}-gke-nodes"
  project      = var.project_id
  display_name = "GKE Node Service Account"
  description  = "Service account for GKE node pool"

  depends_on = [google_project_service.apis]
}

# IAM roles for GKE node service account
resource "google_project_iam_member" "gke_node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/artifactregistry.reader",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  project_id          = var.project_id
  project_name        = var.project_name
  region              = var.region
  environment         = var.environment
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  pods_cidr           = var.pods_cidr
  services_cidr       = var.services_cidr

  depends_on = [google_project_service.apis]
}

# GKE Module
module "gke" {
  source = "./modules/gke"

  project_id              = var.project_id
  project_name            = var.project_name
  region                  = var.region
  environment             = var.environment
  vpc_id                  = module.networking.vpc_id
  subnet_id               = module.networking.private_subnet_id
  pods_range_name         = module.networking.pods_range_name
  services_range_name     = module.networking.services_range_name
  private_vpc_connection  = module.networking.private_vpc_connection
  node_service_account    = google_service_account.gke_nodes.email
  deletion_protection     = var.gke_deletion_protection
  enable_private_endpoint = var.gke_enable_private_endpoint
  master_authorized_networks = var.gke_master_authorized_networks
  primary_pool_machine_type  = var.gke_machine_type
  primary_pool_min_node_count = var.gke_min_nodes
  primary_pool_max_node_count = var.gke_max_nodes
  create_spot_pool        = var.gke_create_spot_pool

  depends_on = [module.networking, google_service_account.gke_nodes]
}

# Cloud SQL Module
module "cloudsql" {
  source = "./modules/cloudsql"

  project_id             = var.project_id
  project_name           = var.project_name
  region                 = var.region
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  private_vpc_connection = module.networking.private_vpc_connection
  tier                   = var.cloudsql_tier
  availability_type      = var.cloudsql_availability_type
  disk_size              = var.cloudsql_disk_size
  database_name          = var.database_name
  database_user          = var.database_user
  deletion_protection    = var.cloudsql_deletion_protection
  create_read_replica    = var.cloudsql_create_read_replica

  depends_on = [module.networking]
}

# Artifact Registry Module
module "artifact_registry" {
  source = "./modules/artifact-registry"

  project_id                 = var.project_id
  project_name               = var.project_name
  region                     = var.region
  environment                = var.environment
  gke_service_account        = google_service_account.gke_nodes.email
  cloudbuild_service_account = module.cloud_build.service_account_email
  create_helm_repo           = var.create_helm_repo

  depends_on = [google_project_service.apis, module.cloud_build]
}

# Cloud Build Module
module "cloud_build" {
  source = "./modules/cloud-build"

  project_id            = var.project_id
  project_name          = var.project_name
  region                = var.region
  environment           = var.environment
  github_owner          = var.github_owner
  github_repo_name      = var.github_repo_name
  artifact_registry_url = module.artifact_registry.docker_repository_url
  gke_cluster_name      = module.gke.cluster_name
  create_push_trigger   = var.create_cloudbuild_triggers
  create_develop_trigger = var.create_cloudbuild_triggers
  create_pr_trigger     = var.create_cloudbuild_triggers
  create_tag_trigger    = var.create_cloudbuild_triggers

  depends_on = [google_project_service.apis]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  project_id            = var.project_id
  project_name          = var.project_name
  region                = var.region
  environment           = var.environment
  alert_email_addresses = var.alert_email_addresses
  create_gke_alerts     = var.create_monitoring_alerts
  create_cloudsql_alerts = var.create_monitoring_alerts
  uptime_check_urls     = var.uptime_check_urls

  depends_on = [google_project_service.apis]
}

# Secrets Module
module "secrets" {
  source = "./modules/secrets"

  project_id                = var.project_id
  project_name              = var.project_name
  region                    = var.region
  environment               = var.environment
  create_default_secrets    = var.create_default_secrets
  default_secret_accessors  = [google_service_account.gke_nodes.email]
  gke_namespace             = "default"
  gke_service_account_name  = "default"

  depends_on = [google_project_service.apis]
}
