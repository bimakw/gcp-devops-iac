# GCP DevOps Infrastructure as Code

Production-ready GCP infrastructure using Terraform with full DevOps pipeline.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Google Cloud Platform                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                      │
│  │   Cloud     │    │  Artifact   │    │   Secret    │                      │
│  │   Build     │───▶│  Registry   │    │   Manager   │                      │
│  │   (CI/CD)   │    │  (Images)   │    │  (Secrets)  │                      │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                      │
│         │                  │                  │                              │
│         ▼                  ▼                  ▼                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        VPC Network                                   │    │
│  │  ┌─────────────────────────────────────────────────────────────┐    │    │
│  │  │                    GKE Cluster                               │    │    │
│  │  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐        │    │    │
│  │  │  │ ArgoCD  │  │Prometheus│  │ Grafana │  │  Apps   │        │    │    │
│  │  │  │ (GitOps)│  │(Metrics) │  │(Dashbd) │  │         │        │    │    │
│  │  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘        │    │    │
│  │  └─────────────────────────────────────────────────────────────┘    │    │
│  │                              │                                       │    │
│  │  ┌───────────────────────────┴───────────────────────────────┐      │    │
│  │  │                    Private Subnet                          │      │    │
│  │  │  ┌─────────────┐                    ┌─────────────┐       │      │    │
│  │  │  │  Cloud SQL  │                    │   Redis     │       │      │    │
│  │  │  │ (PostgreSQL)│                    │ (Memorystore)│       │      │    │
│  │  │  └─────────────┘                    └─────────────┘       │      │    │
│  │  └────────────────────────────────────────────────────────────┘      │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                     Cloud Monitoring & Logging                       │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │  Metrics    │  │   Logging   │  │  Alerting   │                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

- **GKE Cluster**: Managed Kubernetes with autoscaling
- **Cloud SQL**: Managed PostgreSQL with high availability
- **Artifact Registry**: Private Docker image repository
- **Cloud Build**: CI/CD pipeline with GitOps
- **Secret Manager**: Secure credential management
- **Cloud Monitoring**: Metrics, logging, and alerting
- **ArgoCD**: GitOps continuous deployment
- **Prometheus + Grafana**: Application monitoring stack

## Prerequisites

- Google Cloud SDK (`gcloud`)
- Terraform >= 1.5
- kubectl
- Helm 3

## Quick Start

### 1. Setup GCP Project

```bash
# Login to GCP
gcloud auth login
gcloud auth application-default login

# Set project
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable \
  compute.googleapis.com \
  container.googleapis.com \
  sqladmin.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  secretmanager.googleapis.com \
  monitoring.googleapis.com \
  logging.googleapis.com
```

### 2. Initialize Terraform

```bash
cd terraform/environments/dev

# Initialize
terraform init

# Plan
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars"
```

### 3. Configure kubectl

```bash
gcloud container clusters get-credentials <cluster-name> --region <region>
```

### 4. Deploy Kubernetes Components

```bash
# ArgoCD
kubectl apply -k kubernetes/argocd/

# Prometheus + Grafana
kubectl apply -k kubernetes/prometheus/
kubectl apply -k kubernetes/grafana/
```

## Project Structure

```
gcp-devops-iac/
├── terraform/
│   ├── modules/
│   │   ├── networking/      # VPC, Subnets, Firewall, NAT
│   │   ├── gke/             # GKE Cluster, Node Pools
│   │   ├── cloudsql/        # Cloud SQL PostgreSQL
│   │   ├── artifact-registry/ # Container Registry
│   │   ├── cloud-build/     # CI/CD Triggers
│   │   ├── monitoring/      # Monitoring, Logging, Alerting
│   │   └── secrets/         # Secret Manager
│   ├── environments/
│   │   ├── dev/            # Development environment
│   │   ├── staging/        # Staging environment
│   │   └── prod/           # Production environment
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── kubernetes/
│   ├── argocd/             # ArgoCD manifests
│   ├── prometheus/         # Prometheus stack
│   ├── grafana/            # Grafana dashboards
│   └── apps/               # Application deployments
├── cloudbuild/
│   └── cloudbuild.yaml     # CI/CD pipeline config
└── docs/
    └── architecture.md
```

## Environments

| Environment | Purpose | Resources |
|-------------|---------|-----------|
| dev | Development & testing | Small instances, single node |
| staging | Pre-production validation | Medium instances, HA |
| prod | Production workloads | Large instances, full HA |

## Security Features

- Private GKE cluster with authorized networks
- Cloud SQL with private IP only
- Workload Identity for pod authentication
- Secret Manager for sensitive data
- VPC Service Controls (optional)
- Binary Authorization (optional)

## Monitoring & Observability

- Cloud Monitoring dashboards
- Custom metrics with Prometheus
- Grafana visualization
- Alerting policies with PagerDuty/Slack integration
- Distributed tracing (optional)

## Cost Optimization

- Preemptible/Spot VMs for non-critical workloads
- Cluster autoscaling
- Resource quotas and limits
- Committed use discounts (CUDs)

## License

MIT License with Attribution - See [LICENSE](LICENSE)

© 2024 Bima Kharisma Wicaksana
