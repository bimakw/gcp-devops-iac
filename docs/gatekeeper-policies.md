# OPA Gatekeeper Policies

Kubernetes Policy-as-Code menggunakan OPA Gatekeeper untuk enforce security dan best practices.

## Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Kubernetes API                            │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────────┐
│                   Admission Controller                            │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                    OPA Gatekeeper                          │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │  │
│  │  │ Constraint  │  │ Constraint  │  │ Constraint  │        │  │
│  │  │ Templates   │  │   (Rules)   │  │   Audit     │        │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                             │
                             ▼
                    ┌────────┴────────┐
                    │  Allow / Deny   │
                    └─────────────────┘
```

## Policies Implemented

### Security Policies

| Policy | Action | Description |
|--------|--------|-------------|
| Block Privileged | deny | Block containers running in privileged mode |
| Block Host Namespace | deny | Block hostNetwork, hostPID, hostIPC |
| Allowed Repos | deny | Restrict images to approved registries |
| Block Latest Tag | warn | Prevent use of :latest tag |

### Resource Management

| Policy | Action | Description |
|--------|--------|-------------|
| Require Resources | deny | Require CPU/memory limits and requests |
| Require Probes | warn | Require liveness/readiness probes |

### Best Practices

| Policy | Action | Description |
|--------|--------|-------------|
| Require Labels | deny | Require app, team, environment labels |

## Installation

### 1. Install Gatekeeper

```bash
# Using kubectl
kubectl apply -k kubernetes/gatekeeper/base/

# Or using Helm (recommended for production)
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm install gatekeeper gatekeeper/gatekeeper \
  --namespace gatekeeper-system \
  --create-namespace \
  --set replicas=3 \
  --set auditInterval=60
```

### 2. Apply Constraint Templates

```bash
kubectl apply -k kubernetes/gatekeeper/templates/
```

### 3. Apply Constraints

```bash
kubectl apply -k kubernetes/gatekeeper/constraints/
```

### 4. Apply All at Once

```bash
kubectl apply -k kubernetes/gatekeeper/
```

## Policy Details

### K8sRequiredLabels

Requires specified labels on resources.

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-labels
spec:
  match:
    kinds:
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
  parameters:
    labels:
      - key: app
      - key: team
      - key: environment
        allowedRegex: "^(dev|staging|prod)$"
```

**Example violation:**
```yaml
# This will be REJECTED - missing required labels
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  labels:
    app: my-app
    # Missing: team, environment
```

### K8sBlockPrivileged

Blocks privileged containers.

```yaml
# This will be REJECTED
containers:
  - name: my-container
    securityContext:
      privileged: true  # NOT ALLOWED
```

### K8sRequiredResources

Requires resource limits and requests.

```yaml
# This will be REJECTED - missing resources
containers:
  - name: my-container
    image: my-image:v1
    # Missing: resources.limits, resources.requests

# Correct configuration:
containers:
  - name: my-container
    image: my-image:v1
    resources:
      limits:
        cpu: "500m"
        memory: "256Mi"
      requests:
        cpu: "100m"
        memory: "128Mi"
```

### K8sAllowedRepos

Restricts images to approved registries.

```yaml
# This will be REJECTED - unauthorized registry
containers:
  - name: my-container
    image: untrusted-registry.com/my-image:v1

# Allowed registries:
# - asia-southeast1-docker.pkg.dev/
# - gcr.io/
# - docker.io/library/
```

### K8sBlockLatestTag

Blocks :latest tag usage.

```yaml
# This will generate WARNING
containers:
  - name: my-container
    image: my-image:latest  # NOT RECOMMENDED

# Correct:
containers:
  - name: my-container
    image: my-image:v1.2.3  # Specific version
```

## Enforcement Actions

| Action | Behavior |
|--------|----------|
| `deny` | Block the request immediately |
| `warn` | Allow but show warning message |
| `dryrun` | Log only, don't enforce |

## Checking Violations

### View All Violations

```bash
kubectl get constraints -o wide
```

### View Specific Constraint Violations

```bash
kubectl describe k8srequiredlabels require-labels-on-deployments
```

### Audit Existing Resources

```bash
# View audit results
kubectl get k8srequiredlabels -o yaml | grep -A 100 violations
```

## Exemptions

### Exclude Namespaces

```yaml
spec:
  match:
    excludedNamespaces:
      - kube-system
      - gatekeeper-system
      - my-exempt-namespace
```

### Exclude Specific Images

```yaml
spec:
  parameters:
    exemptImages:
      - "gcr.io/google-containers/*"
      - "*/special-image:*"
```

## Troubleshooting

### Check Gatekeeper Status

```bash
kubectl get pods -n gatekeeper-system
kubectl logs -n gatekeeper-system -l control-plane=controller-manager
```

### Check Constraint Status

```bash
kubectl get constrainttemplates
kubectl get constraints
```

### Debug Denied Requests

```bash
# View rejection reason
kubectl describe k8sblockprivileged block-privileged-containers

# Check Gatekeeper webhook logs
kubectl logs -n gatekeeper-system deployment/gatekeeper-controller-manager
```

## Best Practices

1. **Start with `warn`** - Use warn action initially, then switch to deny
2. **Exclude system namespaces** - Always exclude kube-system and gatekeeper-system
3. **Use audit mode** - Enable audit to find existing violations
4. **Document exemptions** - Always document why an exemption is needed
5. **Version constraints** - Use GitOps to manage constraint versions
