# Sealed Secrets Examples

This directory contains example SealedSecrets templates.

## How to Create a SealedSecret

### 1. Install kubeseal CLI

```bash
# macOS
brew install kubeseal

# Linux
KUBESEAL_VERSION=0.24.5
wget "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"
tar -xvzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

### 2. Create a regular Secret

```yaml
# secret.yaml (DO NOT COMMIT THIS!)
apiVersion: v1
kind: Secret
metadata:
  name: my-secret
  namespace: default
type: Opaque
stringData:
  username: admin
  password: super-secret-password
```

### 3. Seal the Secret

```bash
# Fetch the public key from the cluster
kubeseal --fetch-cert \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=sealed-secrets \
  > pub-sealed-secrets.pem

# Seal the secret
kubeseal --format yaml \
  --cert pub-sealed-secrets.pem \
  < secret.yaml \
  > sealed-secret.yaml

# Delete the original secret!
rm secret.yaml
```

### 4. Commit the SealedSecret

```bash
# sealed-secret.yaml is safe to commit
git add sealed-secret.yaml
git commit -m "Add sealed secret for my-app"
```

## Scope Options

### Strict (default)
- Bound to exact name and namespace
- Most secure option

```bash
kubeseal --scope strict ...
```

### Namespace-wide
- Can be renamed within the same namespace

```bash
kubeseal --scope namespace-wide ...
```

### Cluster-wide
- Can be decrypted in any namespace
- Least secure, use sparingly

```bash
kubeseal --scope cluster-wide ...
```
