# Cost Optimization Guide

This guide covers cost management and optimization strategies using the GCP DevOps IaC infrastructure.

## Overview

The cost management module provides:
- **Budget Alerts**: Proactive notifications when spending approaches thresholds
- **Cost Allocation**: Resource labeling for accurate cost attribution
- **Anomaly Detection**: Automatic detection of unusual spending patterns
- **Recommendations**: Integration with GCP Recommender for optimization suggestions
- **Dashboards**: Grafana and Kubecost dashboards for visualization

## Components

### 1. Terraform Cost Management Module

Located in `terraform/modules/cost-management/`

```hcl
module "cost_management" {
  source = "./modules/cost-management"

  project_id         = var.project_id
  project_name       = var.project_name
  region             = var.region
  environment        = var.environment
  billing_account_id = var.billing_account_id

  # Budget configuration
  monthly_budget_amount = 1000  # USD
  currency_code         = "USD"

  # Alert thresholds (percentages)
  budget_alert_thresholds = [50, 80, 90, 100, 110]

  # Notification channels
  notification_channels = [
    google_monitoring_notification_channel.email.name,
    google_monitoring_notification_channel.slack.name
  ]

  # Per-service budgets (optional)
  service_budgets = {
    compute = {
      service_id = "services/6F81-5844-456A"  # Compute Engine
      amount     = 500
    }
    gke = {
      service_id = "services/152E-C115-5142"  # GKE
      amount     = 300
    }
  }

  # Cost allocation labels
  cost_center = "engineering"
  team        = "platform"
}
```

### 2. Kubecost Integration

Kubecost provides Kubernetes-native cost monitoring with GCP integration.

**Deployment:**
```bash
kubectl apply -k kubernetes/cost-monitoring/
```

**Features:**
- Real-time cost allocation by namespace, deployment, and pod
- GCP billing integration via BigQuery
- Cost efficiency recommendations
- Showback/chargeback reports

### 3. Grafana Cost Dashboard

A pre-configured dashboard for cost visualization:

- Daily costs by service trend
- Cost distribution pie charts
- Budget utilization gauge
- Month-to-date spending
- Top SKUs by cost

**Access:**
```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
# Navigate to Dashboards > GCP Cost Dashboard
```

## Budget Alert Configuration

### Alert Thresholds

Default thresholds notify at:
- **50%**: Early warning
- **80%**: Warning
- **90%**: Critical warning
- **100%**: Budget exceeded
- **110%**: Overspend alert

### Notification Channels

Configure in Terraform:

```hcl
# Email notification
resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "Cost Alert Email"
  type         = "email"

  labels = {
    email_address = "finops@example.com"
  }
}

# Slack notification
resource "google_monitoring_notification_channel" "slack" {
  project      = var.project_id
  display_name = "Cost Alert Slack"
  type         = "slack"

  labels = {
    channel_name = "#cost-alerts"
  }

  sensitive_labels {
    auth_token = var.slack_auth_token
  }
}
```

### Pub/Sub Integration

Budget alerts are published to Pub/Sub for custom processing:

```bash
# Subscribe to budget alerts
gcloud pubsub subscriptions pull ${PROJECT_NAME}-budget-alerts-sub \
  --auto-ack --limit=10
```

## Cost Allocation Labels

### Standard Labels

Apply these labels to all resources:

| Label | Description | Example |
|-------|-------------|---------|
| `environment` | Deployment environment | `prod`, `staging`, `dev` |
| `team` | Owning team | `platform`, `backend`, `data` |
| `cost_center` | Cost center code | `engineering`, `sales` |
| `project` | Project name | `gcp-devops` |
| `managed_by` | Management tool | `terraform` |

### Terraform Configuration

```hcl
locals {
  common_labels = {
    environment  = var.environment
    team         = "platform"
    cost_center  = "engineering"
    project      = var.project_name
    managed_by   = "terraform"
  }
}

resource "google_compute_instance" "example" {
  # ...
  labels = local.common_labels
}
```

## Cost Optimization Recommendations

### Using GCP Recommender

The cost management module enables the Recommender API automatically.

**Get recommendations:**
```bash
# VM right-sizing
gcloud recommender recommendations list \
  --project=$PROJECT_ID \
  --location=$REGION \
  --recommender=google.compute.instance.MachineTypeRecommender

# Idle resources
gcloud recommender recommendations list \
  --project=$PROJECT_ID \
  --location=$REGION \
  --recommender=google.compute.instance.IdleResourceRecommender

# Committed use discounts
gcloud recommender recommendations list \
  --project=$PROJECT_ID \
  --location=global \
  --recommender=google.compute.commitment.UsageCommitmentRecommender
```

### Cost Report Script

Use the provided script for quick cost analysis:

```bash
# Full report
./scripts/cost-report.sh all

# Specific reports
./scripts/cost-report.sh costs         # Current month by service
./scripts/cost-report.sh daily         # Daily trend
./scripts/cost-report.sh labels        # Cost by label
./scripts/cost-report.sh recommendations # Optimization recommendations
./scripts/cost-report.sh budget        # Budget status
./scripts/cost-report.sh summary       # Quick summary
```

## BigQuery Billing Export

### Setup

1. Enable billing export in GCP Console:
   - Billing > Billing export > BigQuery export
   - Select dataset created by Terraform

2. Query billing data:

```sql
-- Daily costs by service
SELECT
  DATE(usage_start_time) AS date,
  service.description AS service,
  SUM(cost) AS cost
FROM `project.billing_export.gcp_billing_export_v1_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
GROUP BY date, service
ORDER BY date DESC, cost DESC;

-- Cost by environment label
SELECT
  IFNULL(labels.value, 'unlabeled') AS environment,
  SUM(cost) AS cost
FROM `project.billing_export.gcp_billing_export_v1_*`,
UNNEST(labels) AS labels
WHERE labels.key = 'environment'
  AND _TABLE_SUFFIX >= FORMAT_DATE('%Y%m%d', DATE_TRUNC(CURRENT_DATE(), MONTH))
GROUP BY environment
ORDER BY cost DESC;
```

## Best Practices

### 1. Resource Right-sizing

- Review Recommender suggestions weekly
- Use preemptible/spot VMs for batch workloads
- Configure autoscaling with appropriate min/max

### 2. Committed Use Discounts

- Analyze 3-month usage patterns before committing
- Start with 1-year commitments
- Consider flexible CUDs for variable workloads

### 3. Storage Optimization

- Use lifecycle rules (implemented in storage modules)
- Choose appropriate storage classes
- Enable object versioning selectively

### 4. Network Optimization

- Minimize cross-region traffic
- Use Cloud CDN for static content
- Consider Private Google Access

### 5. GKE Optimization

- Enable cluster autoscaler
- Use node auto-provisioning
- Consider GKE Autopilot for small workloads
- Use resource quotas and limit ranges

## Troubleshooting

### Budget Alerts Not Firing

1. Verify billing export is configured
2. Check Pub/Sub subscription
3. Verify notification channels

```bash
# Check Pub/Sub messages
gcloud pubsub subscriptions pull ${PROJECT_NAME}-budget-alerts-sub --limit=5

# Check budget configuration
gcloud billing budgets list --billing-account=$BILLING_ACCOUNT
```

### Kubecost Not Showing Data

1. Verify Prometheus connectivity
2. Check GCP integration secret
3. Verify Workload Identity binding

```bash
# Check Kubecost pods
kubectl get pods -n cost-monitoring

# Check logs
kubectl logs -l app=cost-analyzer -n cost-monitoring

# Verify GCP connectivity
kubectl exec -it deploy/kubecost-cost-analyzer -n cost-monitoring -- \
  curl -s http://localhost:9003/api/cloudCost
```

### BigQuery Export Missing Data

1. Verify billing export is enabled
2. Check dataset permissions
3. Wait for data (can take 24+ hours initially)

```bash
# Check if tables exist
bq ls billing_export

# Check recent data
bq query --use_legacy_sql=false "
SELECT MAX(export_time)
FROM \`${PROJECT_ID}.billing_export.gcp_billing_export_v1_*\`
"
```

## Related Documentation

- [GCP Budget Alerts](https://cloud.google.com/billing/docs/how-to/budgets)
- [Cloud Recommender](https://cloud.google.com/recommender/docs)
- [Kubecost](https://docs.kubecost.com/)
- [BigQuery Billing Export](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
