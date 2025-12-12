/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Artifact Registry Module - Outputs
 */

output "docker_repository_id" {
  description = "Docker Repository ID"
  value       = google_artifact_registry_repository.docker.id
}

output "docker_repository_name" {
  description = "Docker Repository Name"
  value       = google_artifact_registry_repository.docker.name
}

output "docker_repository_url" {
  description = "Docker Repository URL for pushing/pulling images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.name}"
}

output "npm_repository_url" {
  description = "NPM Repository URL"
  value       = var.create_npm_repo ? "https://${var.region}-npm.pkg.dev/${var.project_id}/${google_artifact_registry_repository.npm[0].name}/" : null
}

output "maven_repository_url" {
  description = "Maven Repository URL"
  value       = var.create_maven_repo ? "https://${var.region}-maven.pkg.dev/${var.project_id}/${google_artifact_registry_repository.maven[0].name}" : null
}

output "python_repository_url" {
  description = "Python Repository URL"
  value       = var.create_python_repo ? "https://${var.region}-python.pkg.dev/${var.project_id}/${google_artifact_registry_repository.python[0].name}/simple/" : null
}

output "helm_repository_url" {
  description = "Helm Repository URL"
  value       = var.create_helm_repo ? "oci://${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.helm[0].name}" : null
}

# Docker authentication command
output "docker_auth_command" {
  description = "Command to authenticate Docker with Artifact Registry"
  value       = "gcloud auth configure-docker ${var.region}-docker.pkg.dev"
}
