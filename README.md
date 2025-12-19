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
- **Memorystore**: Managed Redis for caching with HA support
- **Cloud Armor**: WAF with OWASP rules & DDoS protection
- **Artifact Registry**: Private Docker image repository
- **Cloud Build**: CI/CD pipeline with GitOps
- **Multi-Environment Promotion**: Automated dev → staging → prod pipeline
- **Secret Manager**: Secure credential management
- **Cloud Monitoring**: Metrics, logging, and alerting
- **ArgoCD**: GitOps continuous deployment
- **Prometheus + Grafana**: Application monitoring stack
- **Terraform Validation Pipeline**: Automated security scanning & linting

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
│   │   ├── memorystore/     # Redis Cache (Memorystore)
│   │   ├── cloud-armor/     # WAF & DDoS Protection
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
│   ├── external-secrets/   # External Secrets Operator
│   ├── gatekeeper/         # OPA Gatekeeper policies
│   ├── sealed-secrets/     # Sealed Secrets controller
│   ├── prometheus/         # Prometheus stack
│   ├── grafana/            # Grafana dashboards
│   └── apps/               # Application deployments
├── cloudbuild/
│   ├── cloudbuild.yaml          # CI/CD pipeline config
│   ├── cloudbuild-promote.yaml  # Multi-env promotion
│   └── triggers/                # Trigger configurations
├── scripts/
│   ├── smoke-test.sh            # Automated smoke tests
│   └── rollback.sh              # Emergency rollback
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
- **Terraform Security Pipeline**:
  - TFSec: Security vulnerability scanning
  - Checkov: Policy-as-code compliance
  - TFLint: Best practices enforcement
- **OPA Gatekeeper**: Kubernetes policy-as-code
  - Block privileged containers
  - Enforce resource limits
  - Restrict image registries
  - Require labels and probes
- **Sealed Secrets**: GitOps-friendly secret management
  - Encrypt secrets for Git storage
  - Automatic decryption in cluster
  - ArgoCD integration
- **External Secrets Operator**: Sync secrets from Secret Manager
  - Workload Identity authentication
  - Automatic secret refresh
  - Template transformation

## Monitoring & Observability

- Cloud Monitoring dashboards
- Custom metrics with Prometheus
- Grafana visualization
- Alerting policies with PagerDuty/Slack integration
- Distributed tracing (optional)
- **SLO/SLI Monitoring**:
  - Multi-window burn rate alerts
  - Recording rules for efficient queries
  - SLO Overview dashboard
  - Service Health dashboard
  - Error budget tracking

## Cost Optimization

- Preemptible/Spot VMs for non-critical workloads
- Cluster autoscaling
- Resource quotas and limits
- Committed use discounts (CUDs)

## License

MIT License with Attribution - See [LICENSE](LICENSE)

© 2024 Bima Kharisma Wicaksana
