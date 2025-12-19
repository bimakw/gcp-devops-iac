# Disaster Recovery with Velero

This document describes the Kubernetes backup and disaster recovery strategy using Velero.

## Overview

Velero provides:
- Kubernetes resource backup to GCS
- Persistent volume snapshots
- Scheduled backups
- Point-in-time restore
- Cluster migration capabilities

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    Velero Server                      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
│  │  │   Backup    │  │  Restore    │  │  Schedule   │   │   │
│  │  │ Controller  │  │ Controller  │  │ Controller  │   │   │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘   │   │
│  └─────────┼────────────────┼────────────────┼──────────┘   │
│            │                │                │               │
│  ┌─────────┼────────────────┼────────────────┼──────────┐   │
│  │         │    Velero Node Agent (per node)  │          │   │
│  │         │    (File system backups)         │          │   │
│  │         └────────────────┬─────────────────┘          │   │
│  └──────────────────────────┼────────────────────────────┘   │
└─────────────────────────────┼────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   GCS Bucket     │ │  GCE Snapshots   │ │  Backup Metadata │
│  (Backups)       │ │ (PV Snapshots)   │ │   (JSON/YAML)    │
└──────────────────┘ └──────────────────┘ └──────────────────┘
```

## Setup

### 1. Create Infrastructure (Terraform)

```bash
# The velero-storage module creates:
# - GCS bucket for backups
# - Service account with permissions
# - Workload Identity binding

cd terraform/environments/dev
terraform apply -var="create_velero=true"
```

### 2. Deploy Velero

```bash
# Update kustomization with your project values
sed -i "s/YOUR_PROJECT_ID/${PROJECT_ID}/g" kubernetes/velero/kustomization.yaml

# Deploy
kubectl apply -k kubernetes/velero/

# Apply schedules
kubectl apply -f kubernetes/velero/schedules.yaml
```

### 3. Verify Installation

```bash
# Check Velero deployment
kubectl get deployments -n velero

# Check backup location
velero backup-location get

# Check snapshot location
velero snapshot-location get
```

## Backup Operations

### Manual Backup

```bash
# Full cluster backup
velero backup create full-backup-$(date +%Y%m%d)

# Namespace backup
velero backup create ns-backup --include-namespaces production

# With labels
velero backup create app-backup --selector app=myapp
```

### Check Backup Status

```bash
# List backups
velero backup get

# Describe backup
velero backup describe <backup-name>

# View logs
velero backup logs <backup-name>
```

## Scheduled Backups

| Schedule | Frequency | Retention | Scope |
|----------|-----------|-----------|-------|
| `daily-full-backup` | Daily 2 AM | 7 days | All namespaces |
| `weekly-backup` | Sunday 3 AM | 30 days | All namespaces |
| `critical-apps-backup` | Every 6 hours | 3 days | production, default |

## Restore Operations

### Using Script

```bash
# List available backups
./scripts/velero-restore.sh --list

# Dry run
./scripts/velero-restore.sh daily-full-backup-20240101020000 --dry-run

# Full restore
./scripts/velero-restore.sh daily-full-backup-20240101020000

# Namespace restore
./scripts/velero-restore.sh daily-full-backup-20240101020000 -n production
```

### Manual Restore

```bash
# Full restore
velero restore create --from-backup <backup-name>

# Namespace restore
velero restore create --from-backup <backup-name> --include-namespaces production

# Exclude resources
velero restore create --from-backup <backup-name> --exclude-resources secrets

# Check restore status
velero restore get
velero restore describe <restore-name>
```

## Disaster Recovery Scenarios

### Scenario 1: Namespace Deleted

```bash
# Identify latest backup
velero backup get

# Restore specific namespace
velero restore create --from-backup daily-full-backup-20240101020000 \
  --include-namespaces deleted-namespace
```

### Scenario 2: Cluster Migration

```bash
# On source cluster
velero backup create migration-backup

# On target cluster (with same backup location)
velero restore create --from-backup migration-backup
```

### Scenario 3: Full Cluster Recovery

```bash
# List backups
velero backup get

# Restore everything
velero restore create full-restore --from-backup weekly-backup-20240101030000

# Wait for completion
velero restore wait full-restore
```

## Best Practices

1. **Test restores regularly** - Don't wait for a disaster
2. **Use multiple schedules** - Different retention for different needs
3. **Monitor backup status** - Alert on failed backups
4. **Encrypt backups** - Enable GCS encryption
5. **Cross-region replication** - For critical data
6. **Document recovery procedures** - Include RTO/RPO targets

## Monitoring

### Prometheus Metrics

```yaml
# Add to Prometheus scrape config
- job_name: 'velero'
  static_configs:
    - targets: ['velero.velero.svc.cluster.local:8085']
```

### Key Metrics

- `velero_backup_total`
- `velero_backup_success_total`
- `velero_backup_failure_total`
- `velero_restore_total`

## Troubleshooting

### Backup Failed

```bash
# Check backup logs
velero backup logs <backup-name>

# Check Velero server logs
kubectl logs -n velero -l app.kubernetes.io/name=velero
```

### Restore Incomplete

```bash
# Check restore logs
velero restore logs <restore-name>

# Check for warnings
velero restore describe <restore-name> --details
```

### Common Issues

1. **Permission denied**: Check service account IAM roles
2. **Snapshot failed**: Verify compute.storageAdmin role
3. **Backup stuck**: Check node agent pods

## References

- [Velero Documentation](https://velero.io/docs/)
- [GCP Plugin](https://github.com/vmware-tanzu/velero-plugin-for-gcp)
- [Backup Best Practices](https://velero.io/docs/main/backup-best-practices/)
