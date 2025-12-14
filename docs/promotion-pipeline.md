# Multi-Environment Promotion Pipeline

Copyright (c) 2024 Bima Kharisma Wicaksana

## Overview

Pipeline otomatis untuk promosi deployment antar environment dengan approval gates dan automated testing.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     Multi-Environment Pipeline                           │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  GitHub                Cloud Build                    GKE Clusters       │
│  ┌──────────┐         ┌───────────┐                  ┌──────────────┐   │
│  │  Push to │────────▶│  Build &  │─────────────────▶│     DEV      │   │
│  │   main   │         │   Test    │                  │  (app-dev)   │   │
│  └──────────┘         └─────┬─────┘                  └──────┬───────┘   │
│                             │                               │           │
│                             │ Smoke Tests Pass              │           │
│                             ▼                               ▼           │
│                       ┌───────────┐                  ┌──────────────┐   │
│                       │  Auto     │─────────────────▶│   STAGING    │   │
│                       │  Promote  │                  │(app-staging) │   │
│                       └─────┬─────┘                  └──────┬───────┘   │
│                             │                               │           │
│                             │ Manual Approval               │           │
│                             ▼                               ▼           │
│                       ┌───────────┐                  ┌──────────────┐   │
│                       │  Approved │─────────────────▶│    PROD      │   │
│                       │  Deploy   │                  │  (app-prod)  │   │
│                       └───────────┘                  └──────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Pipeline Flow

### 1. Development (Automatic)

```
Push to main → Build Image → Deploy to Dev → Smoke Tests → Auto-promote to Staging
```

### 2. Staging (Automatic)

```
Staging Deploy → Smoke Tests → Wait for Approval
```

### 3. Production (Manual Approval)

```
Approval Request → Approved → Deploy to Prod → Smoke Tests → Complete
```

## Environment Differences

| Aspect | Dev | Staging | Prod |
|--------|-----|---------|------|
| Replicas | 1 | 2 | 3-10 |
| CPU Request | 50m | 100m | 200m |
| Memory Request | 64Mi | 128Mi | 256Mi |
| CPU Limit | 200m | 500m | 1000m |
| Memory Limit | 256Mi | 512Mi | 1Gi |
| HPA Min | 1 | 2 | 3 |
| HPA Max | 2 | 5 | 10 |
| Log Level | debug | info | warn |
| PDB | No | No | Yes (min 2) |

## Setup

### 1. Create Cloud Build Triggers

```bash
# Deploy to Dev (on push to main)
gcloud builds triggers create github \
  --name="deploy-to-dev" \
  --repo-name="gcp-devops-iac" \
  --repo-owner="bimakw" \
  --branch-pattern="^main$" \
  --build-config="cloudbuild/cloudbuild-promote.yaml" \
  --substitutions="_ENV=dev"

# Promote to Staging (triggered by dev)
gcloud builds triggers create manual \
  --name="promote-to-staging" \
  --build-config="cloudbuild/cloudbuild-promote.yaml" \
  --substitutions="_ENV=staging"

# Promote to Production (requires approval)
gcloud builds triggers create manual \
  --name="promote-to-prod" \
  --build-config="cloudbuild/cloudbuild-promote.yaml" \
  --substitutions="_ENV=prod" \
  --require-approval
```

### 2. Configure Approval (Production)

```bash
# Add approvers for production trigger
gcloud builds triggers update promote-to-prod \
  --require-approval \
  --approval-config-file=cloudbuild/approval-config.yaml
```

### 3. Create GKE Namespaces

```bash
# Dev
kubectl apply -k kubernetes/apps/overlays/dev

# Staging
kubectl apply -k kubernetes/apps/overlays/staging

# Production
kubectl apply -k kubernetes/apps/overlays/prod
```

## Usage

### Deploy to Development

Automatic on push to main:

```bash
git push origin main
```

### Promote to Staging

Automatic after dev tests pass, or manual:

```bash
gcloud builds triggers run promote-to-staging \
  --substitutions=_IMAGE_TAG=abc123
```

### Promote to Production

Requires approval:

```bash
# Request deployment
gcloud builds triggers run promote-to-prod \
  --substitutions=_IMAGE_TAG=abc123

# Approve the build (done by approver)
gcloud builds approve BUILD_ID
```

### Rollback

Emergency rollback to previous version:

```bash
# Rollback to previous version
./scripts/rollback.sh prod

# Rollback to specific revision
./scripts/rollback.sh prod 5
```

## Smoke Tests

Automated tests run after each deployment:

| Test | Description |
|------|-------------|
| Namespace exists | Verify namespace is created |
| Deployment ready | Check replicas are running |
| Pods running | Verify pods are healthy |
| Service exists | Check service is created |
| HPA configured | Verify autoscaling is set |
| Health endpoint | Test /health returns 200 |
| Ready endpoint | Test /ready returns 200 |
| Metrics endpoint | Test /metrics returns 200 |
| Resource limits | Verify limits are set |
| Liveness probe | Check probe is configured |
| Readiness probe | Check probe is configured |
| Security context | Verify security settings |

Run manually:

```bash
./scripts/smoke-test.sh dev
./scripts/smoke-test.sh staging
./scripts/smoke-test.sh prod
```

## Kustomize Structure

```
kubernetes/apps/
├── base/
│   ├── deployment.yaml      # Base deployment template
│   ├── service.yaml         # Service definition
│   ├── hpa.yaml             # HPA template
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml   # Dev overrides
    ├── staging/
    │   └── kustomization.yaml   # Staging overrides
    └── prod/
        ├── kustomization.yaml   # Prod overrides
        └── pdb.yaml             # Pod Disruption Budget
```

### Preview Changes

```bash
# Preview dev manifests
kustomize build kubernetes/apps/overlays/dev

# Preview staging manifests
kustomize build kubernetes/apps/overlays/staging

# Preview prod manifests
kustomize build kubernetes/apps/overlays/prod
```

## Best Practices

### 1. Image Tags

- Dev: `dev-latest` (rolling)
- Staging: `staging-latest` (rolling)
- Prod: `v1.2.3` (immutable semantic version)

### 2. Approval Process

- Always require 2 approvers for production
- Document reason for each production deployment
- Keep audit trail of approvals

### 3. Rollback Strategy

- Keep last 10 revisions for each deployment
- Document rollback procedures
- Practice rollback in staging first

### 4. Monitoring

- Set up alerts for failed deployments
- Monitor error rate after each promotion
- Use canary deployments for high-risk changes

## Troubleshooting

### Build Failed

```bash
# Check build logs
gcloud builds log BUILD_ID

# Retry build
gcloud builds triggers run TRIGGER_NAME
```

### Deployment Stuck

```bash
# Check deployment status
kubectl rollout status deployment/prod-app -n app-prod

# Check pod events
kubectl describe pods -n app-prod -l app.kubernetes.io/name=app
```

### Smoke Tests Failed

```bash
# Run tests manually
./scripts/smoke-test.sh prod

# Check pod logs
kubectl logs -n app-prod -l app.kubernetes.io/name=app
```

## File Structure

```
cloudbuild/
├── cloudbuild-promote.yaml    # Main promotion pipeline
└── triggers/
    ├── dev-deploy.yaml        # Dev trigger config
    ├── staging-promote.yaml   # Staging trigger config
    └── prod-promote.yaml      # Prod trigger config

scripts/
├── smoke-test.sh              # Smoke test script
└── rollback.sh                # Rollback script
```

## References

- [Cloud Build Approvals](https://cloud.google.com/build/docs/securing-builds/gate-builds-on-approval)
- [Kustomize Documentation](https://kustomize.io/)
- [GKE Deployment Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices/deploying-workloads)
