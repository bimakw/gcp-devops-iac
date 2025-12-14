# Sealed Secrets for GitOps

Copyright (c) 2024 Bima Kharisma Wicaksana

## Overview

Sealed Secrets adalah solusi untuk menyimpan Kubernetes Secrets secara aman di Git repository. Secret di-encrypt menggunakan public key dari cluster, sehingga hanya cluster yang bisa decrypt.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GitOps Flow                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Developer                Git Repository              Cluster    │
│  ┌────────┐              ┌─────────────┐         ┌──────────┐   │
│  │ Secret │──kubeseal───▶│ SealedSecret│──ArgoCD─▶│  Secret  │   │
│  │ (YAML) │              │   (YAML)    │   Sync   │(Decrypted)│  │
│  └────────┘              └─────────────┘         └──────────┘   │
│       │                        │                      ▲         │
│       │                        │                      │         │
│       ▼                        ▼                      │         │
│  ┌────────────────────────────────────────────────────┘         │
│  │              Sealed Secrets Controller                        │
│  │  • Holds private key                                          │
│  │  • Decrypts SealedSecrets                                    │
│  │  • Creates native Secrets                                     │
│  └──────────────────────────────────────────────────────────────│
└─────────────────────────────────────────────────────────────────┘
```

## Installation

### Prerequisites

```bash
# Install kubeseal CLI
# macOS
brew install kubeseal

# Linux
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.5/kubeseal-0.24.5-linux-amd64.tar.gz
tar -xvzf kubeseal-0.24.5-linux-amd64.tar.gz
sudo mv kubeseal /usr/local/bin/
```

### Deploy Controller

Controller di-deploy via ArgoCD:

```bash
# ArgoCD akan sync dari kubernetes/sealed-secrets/
kubectl apply -f kubernetes/argocd/applications/sealed-secrets.yaml
```

Atau manual dengan kustomize:

```bash
kubectl apply -k kubernetes/sealed-secrets/
```

## Usage

### 1. Create a Secret (Don't Commit This!)

```bash
# Generic secret
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=supersecret \
  --dry-run=client -o yaml > my-secret.yaml
```

### 2. Seal the Secret

```bash
# Seal using cluster's public key
kubeseal --format yaml < my-secret.yaml > my-sealed-secret.yaml

# Delete the plain secret!
rm my-secret.yaml
```

### 3. Commit SealedSecret

```bash
# Safe to commit
git add my-sealed-secret.yaml
git commit -m "Add sealed secret for my-app"
git push
```

### 4. Apply or Let ArgoCD Sync

```bash
# Manual apply
kubectl apply -f my-sealed-secret.yaml

# Or let ArgoCD sync automatically
```

## Secret Types

### Database Credentials

```bash
kubectl create secret generic db-credentials \
  --from-literal=DB_HOST=postgres.example.com \
  --from-literal=DB_PORT=5432 \
  --from-literal=DB_NAME=myapp \
  --from-literal=DB_USER=appuser \
  --from-literal=DB_PASSWORD=secretpassword \
  --dry-run=client -o yaml | kubeseal --format yaml > db-sealed.yaml
```

### Docker Registry

```bash
kubectl create secret docker-registry regcred \
  --docker-server=asia-southeast1-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(cat service-account-key.json)" \
  --docker-email=sa@project.iam.gserviceaccount.com \
  --dry-run=client -o yaml | kubeseal --format yaml > regcred-sealed.yaml
```

### TLS Certificate

```bash
kubectl create secret tls my-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  --dry-run=client -o yaml | kubeseal --format yaml > tls-sealed.yaml
```

### API Keys

```bash
kubectl create secret generic api-keys \
  --from-literal=STRIPE_KEY=sk_live_xxx \
  --from-literal=SENDGRID_KEY=SG.xxx \
  --dry-run=client -o yaml | kubeseal --format yaml > api-keys-sealed.yaml
```

## Advanced Usage

### Namespace Scoping

By default, SealedSecrets are scoped to a specific namespace:

```bash
# Secret only valid in 'production' namespace
kubectl create secret generic my-secret \
  --namespace production \
  --from-literal=key=value \
  --dry-run=client -o yaml | kubeseal --format yaml > sealed.yaml
```

### Cluster-wide Secrets

```bash
# Can be deployed to any namespace
kubeseal --scope cluster-wide --format yaml < secret.yaml > sealed.yaml
```

### Update Existing Secret

```bash
# Merge new values into existing SealedSecret
kubeseal --merge-into existing-sealed.yaml < new-secret.yaml
```

### Fetch Public Key

```bash
# Get controller's public key for offline sealing
kubeseal --fetch-cert > pub-cert.pem

# Use offline
kubeseal --cert pub-cert.pem --format yaml < secret.yaml > sealed.yaml
```

## Key Management

### Backup Sealing Key

```bash
# IMPORTANT: Backup the sealing key for disaster recovery
kubectl get secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml > sealing-key-backup.yaml

# Store securely (NOT in Git!)
```

### Key Rotation

The controller automatically generates new keys periodically. Old keys are kept to decrypt existing SealedSecrets.

To force rotation:

```bash
kubectl annotate secret -n sealed-secrets \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  sealedsecrets.bitnami.com/sealed-secrets-key-rotation=true
```

### Restore Key (Disaster Recovery)

```bash
# Restore from backup before controller starts
kubectl apply -f sealing-key-backup.yaml

# Restart controller
kubectl rollout restart deployment sealed-secrets-controller -n sealed-secrets
```

## Integration with ArgoCD

### Application Structure

```
kubernetes/
├── my-app/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── sealed-secrets/
│       ├── db-credentials.yaml      # SealedSecret
│       └── api-keys.yaml            # SealedSecret
└── sealed-secrets/
    └── base/                        # Controller
```

### Sync Order

ArgoCD syncs resources in order. SealedSecrets are processed before Deployments that reference them:

```yaml
# In your Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        envFrom:
        - secretRef:
            name: db-credentials  # Created from SealedSecret
```

## Troubleshooting

### Check Controller Status

```bash
kubectl get pods -n sealed-secrets
kubectl logs -n sealed-secrets -l name=sealed-secrets-controller
```

### Verify SealedSecret

```bash
# Check if SealedSecret is synced
kubectl get sealedsecret my-secret -n default

# Check resulting Secret
kubectl get secret my-secret -n default
kubectl get secret my-secret -n default -o jsonpath='{.data}' | base64 -d
```

### Common Issues

1. **"no key could decrypt secret"**
   - Key was rotated or cluster was recreated
   - Solution: Re-seal secrets with new public key

2. **"cannot fetch certificate"**
   - Controller not running
   - Solution: Check controller pod status

3. **"namespace mismatch"**
   - SealedSecret was created for different namespace
   - Solution: Re-seal with correct namespace

## Security Best Practices

1. **Never commit plain Secrets**
   - Add `*.secret.yaml` to `.gitignore`
   - Only commit SealedSecrets

2. **Backup sealing keys**
   - Store in secure vault (not Git!)
   - Required for disaster recovery

3. **Use namespace scoping**
   - Prevents secrets from being used in wrong namespace

4. **Rotate secrets regularly**
   - Re-seal with new values periodically

5. **Audit access**
   - Monitor who can access sealed-secrets namespace

## File Structure

```
kubernetes/sealed-secrets/
├── base/
│   ├── namespace.yaml           # Namespace definition
│   ├── crd.yaml                 # SealedSecret CRD
│   ├── controller.yaml          # Controller deployment
│   └── kustomization.yaml
├── examples/
│   ├── README.md                # Usage examples
│   ├── database-secret.yaml     # Template
│   ├── docker-registry-secret.yaml
│   └── tls-secret.yaml
└── kustomization.yaml
```

## References

- [Sealed Secrets GitHub](https://github.com/bitnami-labs/sealed-secrets)
- [Sealed Secrets Documentation](https://sealed-secrets.netlify.app/)
- [ArgoCD + Sealed Secrets](https://argo-cd.readthedocs.io/en/stable/operator-manual/secret-management/)
