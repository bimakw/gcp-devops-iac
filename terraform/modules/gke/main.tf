/*
 * Copyright (c) 2024 Bima Kharisma Wicaksana
 * GitHub: https://github.com/bimakw
 *
 * GKE Module
 * Creates GKE Cluster with Node Pools and Workload Identity
 */

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.0.0"
    }
  }
}

# GKE Cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_name}-gke"
  project  = var.project_id
  location = var.region

  # Regional cluster for HA
  node_locations = var.node_locations

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = var.vpc_id
  subnetwork = var.subnet_id

  # Private cluster configuration
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # IP allocation policy for VPC-native cluster
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Master authorized networks
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Cluster addons
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = !var.enable_network_policy
    }

    gce_persistent_disk_csi_driver_config {
      enabled = true
    }

    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  # Network policy
  network_policy {
    enabled  = var.enable_network_policy
    provider = var.enable_network_policy ? "CALICO" : "PROVIDER_UNSPECIFIED"
  }

  # Binary Authorization
  dynamic "binary_authorization" {
    for_each = var.enable_binary_authorization ? [1] : []
    content {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
    }
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  # Logging and monitoring
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]

    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # Release channel
  release_channel {
    channel = var.release_channel
  }

  # Cluster autoscaling (for node auto-provisioning)
  dynamic "cluster_autoscaling" {
    for_each = var.enable_node_auto_provisioning ? [1] : []
    content {
      enabled = true

      resource_limits {
        resource_type = "cpu"
        minimum       = var.nap_min_cpu
        maximum       = var.nap_max_cpu
      }

      resource_limits {
        resource_type = "memory"
        minimum       = var.nap_min_memory
        maximum       = var.nap_max_memory
      }

      auto_provisioning_defaults {
        oauth_scopes = [
          "https://www.googleapis.com/auth/cloud-platform"
        ]
        service_account = var.node_service_account
      }
    }
  }

  # Security
  enable_shielded_nodes = true

  # Deletion protection
  deletion_protection = var.deletion_protection

  resource_labels = {
    environment = var.environment
    project     = var.project_name
    managed_by  = "terraform"
  }

  depends_on = [var.private_vpc_connection]
}

# Primary Node Pool
resource "google_container_node_pool" "primary" {
  name     = "${var.project_name}-primary-pool"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.primary.name

  # Node count configuration
  initial_node_count = var.primary_pool_initial_node_count

  # Autoscaling
  autoscaling {
    min_node_count  = var.primary_pool_min_node_count
    max_node_count  = var.primary_pool_max_node_count
    location_policy = "BALANCED"
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  node_config {
    machine_type = var.primary_pool_machine_type
    disk_size_gb = var.primary_pool_disk_size_gb
    disk_type    = var.primary_pool_disk_type

    # Preemptible/Spot VMs for cost savings
    preemptible = var.primary_pool_preemptible
    spot        = var.primary_pool_spot

    # Service account
    service_account = var.node_service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded instance config
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Labels
    labels = {
      environment = var.environment
      pool        = "primary"
    }

    # Tags for firewall rules
    tags = ["gke-node", "${var.project_name}-gke-node"]

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

# Spot/Preemptible Node Pool (for batch jobs, non-critical workloads)
resource "google_container_node_pool" "spot" {
  count = var.create_spot_pool ? 1 : 0

  name     = "${var.project_name}-spot-pool"
  project  = var.project_id
  location = var.region
  cluster  = google_container_cluster.primary.name

  initial_node_count = var.spot_pool_initial_node_count

  autoscaling {
    min_node_count  = var.spot_pool_min_node_count
    max_node_count  = var.spot_pool_max_node_count
    location_policy = "ANY"
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
    strategy        = "SURGE"
  }

  node_config {
    machine_type = var.spot_pool_machine_type
    disk_size_gb = var.spot_pool_disk_size_gb
    disk_type    = "pd-standard"

    spot = true

    service_account = var.node_service_account
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = {
      environment = var.environment
      pool        = "spot"
    }

    # Taint for spot nodes
    taint {
      key    = "cloud.google.com/gke-spot"
      value  = "true"
      effect = "NO_SCHEDULE"
    }

    tags = ["gke-node", "${var.project_name}-gke-spot-node"]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}
