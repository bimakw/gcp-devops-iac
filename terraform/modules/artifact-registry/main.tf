/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Artifact Registry Module
 * Creates Artifact Registry repositories for Docker images, NPM, Maven, etc.
 */

# Docker Repository
resource "google_artifact_registry_repository" "docker" {
  repository_id = "${var.project_name}-docker"
  project       = var.project_id
  location      = var.region
  format        = "DOCKER"
  description   = "Docker repository for ${var.project_name}"

  # Cleanup policies
  dynamic "cleanup_policies" {
    for_each = var.enable_cleanup_policies ? [1] : []
    content {
      id     = "keep-minimum-versions"
      action = "KEEP"

      most_recent_versions {
        keep_count = var.keep_count
      }
    }
  }

  dynamic "cleanup_policies" {
    for_each = var.enable_cleanup_policies ? [1] : []
    content {
      id     = "delete-old-untagged"
      action = "DELETE"

      condition {
        tag_state  = "UNTAGGED"
        older_than = "${var.untagged_retention_days}d"
      }
    }
  }

  labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# NPM Repository (optional)
resource "google_artifact_registry_repository" "npm" {
  count = var.create_npm_repo ? 1 : 0

  repository_id = "${var.project_name}-npm"
  project       = var.project_id
  location      = var.region
  format        = "NPM"
  description   = "NPM repository for ${var.project_name}"

  labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# Maven Repository (optional)
resource "google_artifact_registry_repository" "maven" {
  count = var.create_maven_repo ? 1 : 0

  repository_id = "${var.project_name}-maven"
  project       = var.project_id
  location      = var.region
  format        = "MAVEN"
  description   = "Maven repository for ${var.project_name}"

  maven_config {
    allow_snapshot_overwrites = var.maven_allow_snapshot_overwrites
    version_policy            = var.maven_version_policy
  }

  labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# Python Repository (optional)
resource "google_artifact_registry_repository" "python" {
  count = var.create_python_repo ? 1 : 0

  repository_id = "${var.project_name}-python"
  project       = var.project_id
  location      = var.region
  format        = "PYTHON"
  description   = "Python repository for ${var.project_name}"

  labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }
}

# Helm Repository (optional)
resource "google_artifact_registry_repository" "helm" {
  count = var.create_helm_repo ? 1 : 0

  repository_id = "${var.project_name}-helm"
  project       = var.project_id
  location      = var.region
  format        = "DOCKER"
  mode          = "STANDARD_REPOSITORY"
  description   = "Helm charts repository for ${var.project_name}"

  labels = {
    environment = var.environment
    project     = var.project_name
    type        = "helm"
    managed_by  = "terraform"
  }
}

# IAM Binding - GKE Service Account can pull images
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  count = var.gke_service_account != "" ? 1 : 0

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.gke_service_account}"
}

# IAM Binding - Cloud Build can push images
resource "google_artifact_registry_repository_iam_member" "cloudbuild_writer" {
  count = var.cloudbuild_service_account != "" ? 1 : 0

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.cloudbuild_service_account}"
}

# Additional readers
resource "google_artifact_registry_repository_iam_member" "additional_readers" {
  for_each = toset(var.additional_readers)

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = each.value
}

# Additional writers
resource "google_artifact_registry_repository_iam_member" "additional_writers" {
  for_each = toset(var.additional_writers)

  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.writer"
  member     = each.value
}
