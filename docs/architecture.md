# GCP DevOps Infrastructure Architecture

## Overview

This infrastructure implements a production-ready GCP environment using Terraform modules with GitOps deployment practices.

## Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────────────────────┐
│                                 INTERNET                                              │
└────────────────────────────────────┬─────────────────────────────────────────────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │       Cloud Load Balancer       │
                    │      (HTTPS Termination)        │
                    └────────────────┬────────────────┘
                                     │
┌────────────────────────────────────┼────────────────────────────────────────────────┐
│                              GCP PROJECT                                             │
│                                    │                                                 │
│    ┌───────────────────────────────┴───────────────────────────────────┐            │
│    │                        VPC NETWORK                                 │            │
│    │                                                                    │            │
│    │   ┌─────────────────────────────────────────────────────────┐    │            │
│    │   │                   PUBLIC SUBNET                          │    │            │
│    │   │              (10.0.1.0/24)                               │    │            │
│    │   │   ┌─────────────┐    ┌─────────────┐                    │    │            │
│    │   │   │   Bastion   │    │    NAT      │                    │    │            │
│    │   │   │   (optional)│    │   Gateway   │                    │    │            │
│    │   │   └─────────────┘    └─────────────┘                    │    │            │
│    │   └─────────────────────────────────────────────────────────┘    │            │
│    │                                                                    │            │
│    │   ┌─────────────────────────────────────────────────────────┐    │            │
│    │   │                   PRIVATE SUBNET                         │    │            │
│    │   │              (10.0.2.0/24)                               │    │            │
│    │   │                                                          │    │            │
│    │   │   ┌──────────────────────────────────────────────────┐  │    │            │
│    │   │   │              GKE CLUSTER                          │  │    │            │
│    │   │   │         (Private, VPC-native)                     │  │    │            │
│    │   │   │                                                   │  │    │            │
│    │   │   │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐ │  │    │            │
│    │   │   │  │ ArgoCD  │ │Prometheus│ │ Grafana │ │  Apps  │ │  │    │            │
│    │   │   │  │ (GitOps)│ │(Metrics) │ │(Dashbd) │ │        │ │  │    │            │
│    │   │   │  └─────────┘ └─────────┘ └─────────┘ └────────┘ │  │    │            │
│    │   │   │                                                   │  │    │            │
│    │   │   │  Pods CIDR: 10.1.0.0/16                          │  │    │            │
│    │   │   │  Services CIDR: 10.2.0.0/16                      │  │    │            │
│    │   │   └──────────────────────────────────────────────────┘  │    │            │
│    │   │                          │                               │    │            │
│    │   │   ┌──────────────────────┴──────────────────────────┐   │    │            │
│    │   │   │           PRIVATE SERVICE ACCESS                 │   │    │            │
│    │   │   │                                                  │   │    │            │
│    │   │   │  ┌─────────────┐          ┌─────────────┐       │   │    │            │
│    │   │   │  │  Cloud SQL  │          │   Redis     │       │   │    │            │
│    │   │   │  │ (PostgreSQL)│          │(Memorystore)│       │   │    │            │
│    │   │   │  │  Private IP │          │  (optional) │       │   │    │            │
│    │   │   │  └─────────────┘          └─────────────┘       │   │    │            │
│    │   │   └─────────────────────────────────────────────────┘   │    │            │
│    │   └─────────────────────────────────────────────────────────┘    │            │
│    └───────────────────────────────────────────────────────────────────┘            │
│                                                                                      │
│    ┌───────────────────────────────────────────────────────────────────┐            │
│    │                        CI/CD PIPELINE                              │            │
│    │                                                                    │            │
│    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │            │
│    │  │   Cloud     │  │  Artifact   │  │   Secret    │               │            │
│    │  │   Build     │──│  Registry   │  │   Manager   │               │            │
│    │  │  (Triggers) │  │  (Images)   │  │  (Secrets)  │               │            │
│    │  └─────────────┘  └─────────────┘  └─────────────┘               │            │
│    └───────────────────────────────────────────────────────────────────┘            │
│                                                                                      │
│    ┌───────────────────────────────────────────────────────────────────┐            │
│    │                     OBSERVABILITY                                  │            │
│    │                                                                    │            │
│    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐               │            │
│    │  │   Cloud     │  │   Cloud     │  │  Alerting   │               │            │
│    │  │  Monitoring │  │   Logging   │  │  Policies   │               │            │
│    │  └─────────────┘  └─────────────┘  └─────────────┘               │            │
│    └───────────────────────────────────────────────────────────────────┘            │
│                                                                                      │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

## Components

### Networking
- **VPC Network**: Custom VPC with regional routing
- **Public Subnet**: For load balancers and optional bastion host
- **Private Subnet**: For GKE nodes, Cloud SQL, and internal services
- **Cloud NAT**: Outbound internet access for private resources
- **Cloud Router**: BGP routing for NAT
- **Firewall Rules**: IAP SSH, health checks, internal communication

### Compute (GKE)
- **Private Cluster**: No public IPs on nodes
- **VPC-native**: Uses alias IP ranges for pods and services
- **Workload Identity**: Secure GCP service authentication
- **Autoscaling**: Node pool autoscaling enabled
- **Shielded Nodes**: Secure boot and integrity monitoring

### Database (Cloud SQL)
- **PostgreSQL**: Managed PostgreSQL 15
- **Private IP**: No public IP, accessed via VPC peering
- **Automated Backups**: Point-in-time recovery enabled
- **High Availability**: Regional availability (production)
- **Read Replicas**: Optional for read-heavy workloads

### CI/CD (Cloud Build)
- **GitHub Integration**: Webhook triggers for push/PR events
- **Multi-environment**: Separate triggers for dev/staging/prod
- **Security Scanning**: Trivy vulnerability scanning
- **Automated Deployments**: kubectl rollout to GKE

### Observability
- **Cloud Monitoring**: Dashboards and metrics
- **Cloud Logging**: Centralized log aggregation
- **Alert Policies**: CPU, memory, disk, uptime alerts
- **Notification Channels**: Email, Slack, PagerDuty

### Security
- **Secret Manager**: Encrypted secrets storage
- **Workload Identity**: Pod-level GCP authentication
- **Private Services**: No public IPs on internal services
- **IAM**: Least privilege access controls

## Deployment Flow

```
GitHub Push → Cloud Build Trigger → Build & Test → Push Image → Deploy to GKE
     ↓                                                              ↓
  Webhook                                                     ArgoCD Sync
     ↓                                                              ↓
Cloud Build                                               Kubernetes Apply
     ↓                                                              ↓
Artifact Registry                                          Rolling Update
```

## Security Considerations

1. **Network Security**
   - Private GKE cluster with authorized networks
   - Cloud SQL accessible only via private IP
   - Firewall rules limit ingress/egress

2. **Identity & Access**
   - Workload Identity for pod authentication
   - Service accounts with minimal permissions
   - IAP for SSH access (no public SSH)

3. **Data Security**
   - Secrets in Secret Manager (not in code)
   - Encrypted storage at rest
   - TLS encryption in transit

4. **Container Security**
   - Vulnerability scanning in CI/CD
   - Shielded GKE nodes
   - Pod security policies (optional)

## Cost Optimization

- **Preemptible/Spot VMs**: For non-critical workloads
- **Autoscaling**: Scale down during low traffic
- **Committed Use Discounts**: For predictable workloads
- **Regional Resources**: Single region deployment

## License

MIT License with Attribution - See LICENSE file

© 2024 Bima Kharisma Wicaksana
