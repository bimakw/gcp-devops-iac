# TLS Certificate Management

This document describes how to manage TLS certificates using cert-manager with Let's Encrypt.

## Overview

cert-manager automates the management of TLS certificates:
- Automatic certificate issuance from Let's Encrypt
- Automatic renewal before expiry
- Support for HTTP01 and DNS01 challenges
- Wildcard certificate support (DNS01 only)

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Let's Encrypt                            │
│         ┌─────────────────────────────────────┐             │
│         │      ACME Server                     │             │
│         │  (staging / production)              │             │
│         └────────────────┬────────────────────┘             │
└──────────────────────────┼──────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    cert-manager                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │               ClusterIssuer                           │   │
│  │    ┌───────────────┐    ┌───────────────┐            │   │
│  │    │ HTTP01 Solver │    │ DNS01 Solver  │            │   │
│  │    │  (Ingress)    │    │ (Cloud DNS)   │            │   │
│  │    └───────────────┘    └───────────────┘            │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │ Certificate  │  │ Certificate  │  │ Certificate  │       │
│  │  app.com     │  │ *.example.com│  │  internal    │       │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘       │
└─────────┼─────────────────┼─────────────────┼───────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                  Kubernetes Secrets                          │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                tls.crt + tls.key                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Deploy cert-manager

```bash
kubectl apply -k kubernetes/cert-manager/
```

### 2. Create ClusterIssuers

```bash
# Update email address
sed -i 's/your-email@example.com/your-real-email@example.com/g' \
  kubernetes/cert-manager/cluster-issuer-*.yaml

# Apply staging issuer (for testing)
kubectl apply -f kubernetes/cert-manager/cluster-issuer-staging.yaml

# Apply production issuer
kubectl apply -f kubernetes/cert-manager/cluster-issuer-prod.yaml
```

### 3. Request a Certificate

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: my-app-tls
spec:
  secretName: my-app-tls
  dnsNames:
    - myapp.example.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```

## Challenge Types

### HTTP01 Challenge

Best for:
- Single domain certificates
- Simple setup
- Publicly accessible services

```yaml
spec:
  acme:
    solvers:
      - http01:
          ingress:
            class: nginx
```

### DNS01 Challenge

Best for:
- Wildcard certificates
- Internal services
- Domains behind firewall

Requires Cloud DNS access:

```bash
# Create service account
gcloud iam service-accounts create cert-manager \
  --display-name="cert-manager"

# Grant DNS admin access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:cert-manager@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/dns.admin"

# Configure Workload Identity
gcloud iam service-accounts add-iam-policy-binding \
  cert-manager@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[cert-manager/cert-manager]"
```

## Using with Ingress

### Automatic Certificate via Annotation

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls
```

### Manual Certificate

1. Create Certificate resource
2. Reference secret in Ingress

## Certificate Lifecycle

| Event | Timing |
|-------|--------|
| Issued | On creation |
| Valid | 90 days (Let's Encrypt) |
| Renewal | 30 days before expiry |
| Expiry warning | Email from Let's Encrypt |

## Troubleshooting

### Check Certificate Status

```bash
# List certificates
kubectl get certificates -A

# Describe certificate
kubectl describe certificate my-cert

# Check certificate request
kubectl get certificaterequest -A

# Check orders
kubectl get orders -A

# Check challenges
kubectl get challenges -A
```

### Common Issues

1. **Challenge failed**: Check Ingress class matches issuer
2. **Rate limited**: Use staging issuer for testing
3. **DNS not propagated**: Wait or reduce TTL
4. **Webhook timeout**: Check cert-manager webhook pod

### View Logs

```bash
kubectl logs -n cert-manager -l app=cert-manager
kubectl logs -n cert-manager -l app=webhook
```

## Best Practices

1. **Always test with staging** before using production
2. **Use DNS01** for wildcard certificates
3. **Monitor expiry** with Prometheus metrics
4. **Keep email updated** for expiry notifications
5. **Use appropriate renewal window** (default 30 days)

## Rate Limits

Let's Encrypt rate limits:
- 50 certificates per domain per week
- 5 duplicate certificates per week
- 300 new orders per account per 3 hours

Use staging issuer for testing to avoid rate limits.

## References

- [cert-manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Cloud DNS Setup](https://cert-manager.io/docs/configuration/acme/dns01/google/)
