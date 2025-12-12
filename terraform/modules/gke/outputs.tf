/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GKE Module - Outputs
 */

output "cluster_id" {
  description = "GKE Cluster ID"
  value       = google_container_cluster.primary.id
}

output "cluster_name" {
  description = "GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "GKE Cluster CA Certificate"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "GKE Cluster Location"
  value       = google_container_cluster.primary.location
}

output "cluster_self_link" {
  description = "GKE Cluster Self Link"
  value       = google_container_cluster.primary.self_link
}

output "primary_node_pool_name" {
  description = "Primary Node Pool Name"
  value       = google_container_node_pool.primary.name
}

output "spot_node_pool_name" {
  description = "Spot Node Pool Name"
  value       = var.create_spot_pool ? google_container_node_pool.spot[0].name : null
}

output "workload_identity_pool" {
  description = "Workload Identity Pool"
  value       = "${var.project_id}.svc.id.goog"
}

# Connection command
output "get_credentials_command" {
  description = "Command to get cluster credentials"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --region ${var.region} --project ${var.project_id}"
}
