# Istio Service Mesh

This document describes the Istio service mesh setup for advanced traffic management, security, and observability.

## Overview

Istio provides:
- **Traffic Management**: Load balancing, routing, canary deployments
- **Security**: mTLS, authorization policies
- **Observability**: Distributed tracing, metrics, service graph

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Istio Ingress Gateway                         │
│                   (Load Balancer Service)                        │
└─────────────────────────────┬───────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Istio Control Plane                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                        Istiod                             │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐                   │   │
│  │  │  Pilot  │  │ Citadel │  │  Galley │                   │   │
│  │  │(Config) │  │ (Certs) │  │(Validate)│                   │   │
│  │  └─────────┘  └─────────┘  └─────────┘                   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Pod A         │ │   Pod B         │ │   Pod C         │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │
│ │    App      │ │ │ │    App      │ │ │ │    App      │ │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │
│ │ Envoy Proxy │◄─┼─►│ Envoy Proxy │◄─┼─►│ Envoy Proxy │ │
│ │  (Sidecar)  │ │ │ │  (Sidecar)  │ │ │ │  (Sidecar)  │ │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │
└─────────────────┘ └─────────────────┘ └─────────────────┘
        mTLS              mTLS              mTLS
```

## Installation

### 1. Install Istio CLI

```bash
curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/istio-*/bin:$PATH
```

### 2. Deploy Istio

```bash
# Apply namespace
kubectl apply -f kubernetes/istio/namespace.yaml

# Install with operator
istioctl install -f kubernetes/istio/istio-operator.yaml

# Verify installation
istioctl verify-install
```

### 3. Enable Sidecar Injection

```bash
# Label namespace for auto-injection
kubectl label namespace default istio-injection=enabled
```

### 4. Deploy Observability Stack

```bash
# Kiali dashboard
kubectl apply -f kubernetes/istio/kiali.yaml

# Jaeger tracing
kubectl apply -f kubernetes/istio/jaeger.yaml
```

## Traffic Management

### Canary Deployment

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
spec:
  http:
    - route:
        - destination:
            host: app
            subset: v1
          weight: 90
        - destination:
            host: app
            subset: v2
          weight: 10
```

### Blue-Green Deployment

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
spec:
  http:
    - route:
        - destination:
            host: app
            subset: blue  # or green
          weight: 100
```

### Header-Based Routing

```yaml
spec:
  http:
    - match:
        - headers:
            x-version:
              exact: "v2"
      route:
        - destination:
            host: app
            subset: v2
```

## Security

### mTLS Modes

| Mode | Description |
|------|-------------|
| STRICT | Only mTLS traffic allowed |
| PERMISSIVE | Accept both plaintext and mTLS |
| DISABLE | Accept only plaintext |

### Authorization Policy

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: allow-frontend
spec:
  selector:
    matchLabels:
      app: backend
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/default/sa/frontend"]
```

## Observability

### Access Kiali

```bash
kubectl port-forward svc/kiali -n istio-system 20001:20001
# Open http://localhost:20001
```

### Access Jaeger

```bash
kubectl port-forward svc/jaeger-query -n istio-system 16686:16686
# Open http://localhost:16686
```

### Prometheus Metrics

Istio exposes metrics at:
- `istio_requests_total`
- `istio_request_duration_milliseconds`
- `istio_tcp_connections_opened_total`

## Best Practices

1. **Start with PERMISSIVE mTLS** then move to STRICT
2. **Use destination rules** for circuit breakers
3. **Enable access logging** for debugging
4. **Set resource limits** on sidecar proxies
5. **Use namespace isolation** with authorization policies

## Troubleshooting

```bash
# Check proxy status
istioctl proxy-status

# Analyze configuration
istioctl analyze

# Debug specific pod
istioctl proxy-config clusters <pod-name>
istioctl proxy-config routes <pod-name>

# View proxy logs
kubectl logs <pod-name> -c istio-proxy
```

## References

- [Istio Documentation](https://istio.io/latest/docs/)
- [Kiali Documentation](https://kiali.io/docs/)
- [Traffic Management](https://istio.io/latest/docs/concepts/traffic-management/)
