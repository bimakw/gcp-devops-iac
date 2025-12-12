/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * Networking Module - Outputs
 */

output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "VPC Name"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "VPC Self Link"
  value       = google_compute_network.vpc.self_link
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = google_compute_subnetwork.public.id
}

output "public_subnet_name" {
  description = "Public Subnet Name"
  value       = google_compute_subnetwork.public.name
}

output "private_subnet_id" {
  description = "Private Subnet ID"
  value       = google_compute_subnetwork.private.id
}

output "private_subnet_name" {
  description = "Private Subnet Name"
  value       = google_compute_subnetwork.private.name
}

output "private_subnet_self_link" {
  description = "Private Subnet Self Link"
  value       = google_compute_subnetwork.private.self_link
}

output "pods_range_name" {
  description = "GKE Pods Secondary Range Name"
  value       = "${var.project_name}-pods"
}

output "services_range_name" {
  description = "GKE Services Secondary Range Name"
  value       = "${var.project_name}-services"
}

output "router_name" {
  description = "Cloud Router Name"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Cloud NAT Name"
  value       = google_compute_router_nat.nat.name
}

output "private_vpc_connection" {
  description = "Private VPC Connection for Cloud SQL"
  value       = google_service_networking_connection.private_vpc_connection.id
}
