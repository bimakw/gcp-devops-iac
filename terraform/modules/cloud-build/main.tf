/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * Cloud Build Module
 * Creates Cloud Build triggers, service accounts, and configurations
 */

# Cloud Build Service Account
resource "google_service_account" "cloudbuild" {
  account_id   = "${var.project_name}-cloudbuild"
  project      = var.project_id
  display_name = "Cloud Build Service Account for ${var.project_name}"
  description  = "Service account used by Cloud Build for CI/CD"
}

# IAM roles for Cloud Build service account
resource "google_project_iam_member" "cloudbuild_roles" {
  for_each = toset([
    "roles/cloudbuild.builds.builder",
    "roles/artifactregistry.writer",
    "roles/container.developer",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/storage.objectViewer",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.cloudbuild.email}"
}

# GitHub Connection (for GitHub repos)
resource "google_cloudbuildv2_connection" "github" {
  count = var.github_app_installation_id != "" ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = "${var.project_name}-github"

  github_config {
    app_installation_id = var.github_app_installation_id
    authorizer_credential {
      oauth_token_secret_version = var.github_oauth_token_secret
    }
  }
}

# GitHub Repository Link
resource "google_cloudbuildv2_repository" "main" {
  count = var.github_app_installation_id != "" && var.github_repo_name != "" ? 1 : 0

  project           = var.project_id
  location          = var.region
  name              = var.github_repo_name
  parent_connection = google_cloudbuildv2_connection.github[0].name
  remote_uri        = "https://github.com/${var.github_owner}/${var.github_repo_name}.git"
}

# Build Trigger - Push to main/master (Production)
resource "google_cloudbuild_trigger" "push_main" {
  count = var.create_push_trigger ? 1 : 0

  project     = var.project_id
  name        = "${var.project_name}-push-main"
  description = "Trigger on push to main branch"
  location    = var.region

  # GitHub trigger configuration
  dynamic "github" {
    for_each = var.github_app_installation_id == "" && var.github_repo_name != "" ? [1] : []
    content {
      owner = var.github_owner
      name  = var.github_repo_name

      push {
        branch = "^main$|^master$"
      }
    }
  }

  # Cloud Build v2 repository trigger
  dynamic "repository_event_config" {
    for_each = var.github_app_installation_id != "" ? [1] : []
    content {
      repository = google_cloudbuildv2_repository.main[0].id

      push {
        branch = "^main$|^master$"
      }
    }
  }

  service_account = google_service_account.cloudbuild.id
  filename        = var.cloudbuild_filename

  substitutions = merge(
    {
      _PROJECT_NAME     = var.project_name
      _REGION           = var.region
      _ENVIRONMENT      = "prod"
      _ARTIFACT_REPO    = var.artifact_registry_url
      _GKE_CLUSTER_NAME = var.gke_cluster_name
    },
    var.additional_substitutions
  )

  tags = ["push", "main", "production"]
}

# Build Trigger - Push to develop (Staging)
resource "google_cloudbuild_trigger" "push_develop" {
  count = var.create_develop_trigger ? 1 : 0

  project     = var.project_id
  name        = "${var.project_name}-push-develop"
  description = "Trigger on push to develop branch"
  location    = var.region

  dynamic "github" {
    for_each = var.github_app_installation_id == "" && var.github_repo_name != "" ? [1] : []
    content {
      owner = var.github_owner
      name  = var.github_repo_name

      push {
        branch = "^develop$"
      }
    }
  }

  dynamic "repository_event_config" {
    for_each = var.github_app_installation_id != "" ? [1] : []
    content {
      repository = google_cloudbuildv2_repository.main[0].id

      push {
        branch = "^develop$"
      }
    }
  }

  service_account = google_service_account.cloudbuild.id
  filename        = var.cloudbuild_filename

  substitutions = merge(
    {
      _PROJECT_NAME     = var.project_name
      _REGION           = var.region
      _ENVIRONMENT      = "staging"
      _ARTIFACT_REPO    = var.artifact_registry_url
      _GKE_CLUSTER_NAME = var.gke_cluster_name
    },
    var.additional_substitutions
  )

  tags = ["push", "develop", "staging"]
}

# Build Trigger - Pull Request
resource "google_cloudbuild_trigger" "pull_request" {
  count = var.create_pr_trigger ? 1 : 0

  project     = var.project_id
  name        = "${var.project_name}-pull-request"
  description = "Trigger on pull request"
  location    = var.region

  dynamic "github" {
    for_each = var.github_app_installation_id == "" && var.github_repo_name != "" ? [1] : []
    content {
      owner = var.github_owner
      name  = var.github_repo_name

      pull_request {
        branch          = "^main$|^master$|^develop$"
        comment_control = "COMMENTS_ENABLED_FOR_EXTERNAL_CONTRIBUTORS_ONLY"
      }
    }
  }

  dynamic "repository_event_config" {
    for_each = var.github_app_installation_id != "" ? [1] : []
    content {
      repository = google_cloudbuildv2_repository.main[0].id

      pull_request {
        branch = "^main$|^master$|^develop$"
      }
    }
  }

  service_account = google_service_account.cloudbuild.id
  filename        = var.cloudbuild_pr_filename

  substitutions = {
    _PROJECT_NAME  = var.project_name
    _REGION        = var.region
    _ARTIFACT_REPO = var.artifact_registry_url
  }

  tags = ["pull-request", "ci"]
}

# Build Trigger - Tag (Release)
resource "google_cloudbuild_trigger" "tag" {
  count = var.create_tag_trigger ? 1 : 0

  project     = var.project_id
  name        = "${var.project_name}-tag-release"
  description = "Trigger on tag push for releases"
  location    = var.region

  dynamic "github" {
    for_each = var.github_app_installation_id == "" && var.github_repo_name != "" ? [1] : []
    content {
      owner = var.github_owner
      name  = var.github_repo_name

      push {
        tag = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
      }
    }
  }

  dynamic "repository_event_config" {
    for_each = var.github_app_installation_id != "" ? [1] : []
    content {
      repository = google_cloudbuildv2_repository.main[0].id

      push {
        tag = "^v[0-9]+\\.[0-9]+\\.[0-9]+$"
      }
    }
  }

  service_account = google_service_account.cloudbuild.id
  filename        = var.cloudbuild_release_filename

  substitutions = merge(
    {
      _PROJECT_NAME     = var.project_name
      _REGION           = var.region
      _ENVIRONMENT      = "prod"
      _ARTIFACT_REPO    = var.artifact_registry_url
      _GKE_CLUSTER_NAME = var.gke_cluster_name
    },
    var.additional_substitutions
  )

  tags = ["tag", "release", "production"]
}

# Manual Trigger (for manual deployments)
resource "google_cloudbuild_trigger" "manual" {
  count = var.create_manual_trigger ? 1 : 0

  project     = var.project_id
  name        = "${var.project_name}-manual"
  description = "Manual trigger for deployments"
  location    = var.region

  source_to_build {
    uri       = "https://github.com/${var.github_owner}/${var.github_repo_name}"
    ref       = "refs/heads/main"
    repo_type = "GITHUB"
  }

  service_account = google_service_account.cloudbuild.id
  filename        = var.cloudbuild_filename

  substitutions = merge(
    {
      _PROJECT_NAME     = var.project_name
      _REGION           = var.region
      _ENVIRONMENT      = "prod"
      _ARTIFACT_REPO    = var.artifact_registry_url
      _GKE_CLUSTER_NAME = var.gke_cluster_name
    },
    var.additional_substitutions
  )

  tags = ["manual", "deployment"]
}
