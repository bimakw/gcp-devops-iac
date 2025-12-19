# External Secrets Operator

This document describes how to use External Secrets Operator (ESO) to sync secrets from GCP Secret Manager to Kubernetes.

## Overview

External Secrets Operator allows you to:
- Sync secrets from GCP Secret Manager to Kubernetes Secrets
- Use Workload Identity for secure authentication
- Automatically refresh secrets on a schedule
- Transform and template secret data

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GCP Secret Manager                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ db-pass  │  │ api-key  │  │ tls-cert │                   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                   │
└───────┼─────────────┼─────────────┼─────────────────────────┘
        │             │             │
        ▼             ▼             ▼
┌─────────────────────────────────────────────────────────────┐
│              External Secrets Operator                       │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              ClusterSecretStore                       │   │
│  │         (GCP Secret Manager Provider)                 │   │
│  │              Workload Identity Auth                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ExternalSecret│  │ExternalSecret│  │ExternalSecret│       │
│  │  db-creds    │  │   api-keys   │  │   tls-cert   │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
└─────────┼─────────────────┼─────────────────┼───────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                  Kubernetes Secrets                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │ db-creds │  │ api-keys │  │ tls-cert │                   │
│  │ (Opaque) │  │ (Opaque) │  │(tls/tls) │                   │
│  └──────────┘  └──────────┘  └──────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. GKE cluster with Workload Identity enabled
2. GCP Service Account with Secret Manager access
3. IAM binding between Kubernetes SA and GCP SA

## Setup

### 1. Create GCP Service Account

```bash
PROJECT_ID="your-project-id"

# Create service account
gcloud iam service-accounts create external-secrets \
  --display-name="External Secrets Operator"

# Grant Secret Manager access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:external-secrets@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 2. Configure Workload Identity

```bash
# Allow Kubernetes SA to impersonate GCP SA
gcloud iam service-accounts add-iam-policy-binding \
  external-secrets@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[external-secrets/external-secrets]"
```

### 3. Deploy External Secrets Operator

```bash
# Update kustomization.yaml with your project ID
sed -i "s/YOUR_PROJECT_ID/${PROJECT_ID}/g" kubernetes/external-secrets/kustomization.yaml

# Apply
kubectl apply -k kubernetes/external-secrets/
```

### 4. Create ClusterSecretStore

```bash
# Update cluster-secret-store.yaml with your values
sed -i "s/YOUR_PROJECT_ID/${PROJECT_ID}/g" kubernetes/external-secrets/cluster-secret-store.yaml
sed -i "s/YOUR_REGION/asia-southeast1/g" kubernetes/external-secrets/cluster-secret-store.yaml
sed -i "s/YOUR_CLUSTER_NAME/your-cluster/g" kubernetes/external-secrets/cluster-secret-store.yaml

# Apply
kubectl apply -f kubernetes/external-secrets/cluster-secret-store.yaml
```

## Usage

### Basic ExternalSecret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcp-secret-manager
    kind: ClusterSecretStore
  target:
    name: my-secret
  data:
    - secretKey: password
      remoteRef:
        key: my-password-in-secret-manager
```

### With Templates

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-config
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcp-secret-manager
    kind: ClusterSecretStore
  target:
    name: db-config
    template:
      data:
        config.yaml: |
          database:
            host: {{ .host }}
            port: {{ .port }}
            password: {{ .password }}
  data:
    - secretKey: host
      remoteRef:
        key: db-host
    - secretKey: port
      remoteRef:
        key: db-port
    - secretKey: password
      remoteRef:
        key: db-password
```

### Extract JSON Secret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-config
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: gcp-secret-manager
    kind: ClusterSecretStore
  target:
    name: app-config
  dataFrom:
    - extract:
        key: app-config  # JSON secret in Secret Manager
```

## Refresh Intervals

| Use Case | Recommended Interval |
|----------|---------------------|
| Database passwords | 1h |
| API keys | 30m |
| TLS certificates | 24h |
| Configuration | 1h |
| Rapidly rotating secrets | 5m |

## Troubleshooting

### Check ESO Status

```bash
# Check operator pods
kubectl get pods -n external-secrets

# Check ExternalSecret status
kubectl get externalsecret -A

# Describe for errors
kubectl describe externalsecret my-secret
```

### Common Issues

1. **SecretStore not ready**: Check Workload Identity configuration
2. **Permission denied**: Verify IAM roles on GCP SA
3. **Secret not found**: Check secret name in Secret Manager
4. **Sync not working**: Check refreshInterval and ESO logs

### View Logs

```bash
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

## Security Best Practices

1. Use ClusterSecretStore with caution - prefer namespace-scoped SecretStore
2. Apply least-privilege IAM roles
3. Enable audit logging for Secret Manager
4. Use secret rotation where possible
5. Set appropriate refreshInterval for your security requirements

## References

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [GCP Secret Manager Provider](https://external-secrets.io/latest/provider/google-secrets-manager/)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)
