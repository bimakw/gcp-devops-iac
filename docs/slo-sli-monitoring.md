# SLO/SLI Monitoring with Prometheus & Grafana

Copyright (c) 2024 Bima Kharisma Wicaksana

## Overview

Implementasi Service Level Objectives (SLOs) dan Service Level Indicators (SLIs) monitoring menggunakan Prometheus untuk metrics collection dan Grafana untuk visualization.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        SLO/SLI Architecture                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Services                    Prometheus                  Grafana         │
│  ┌─────────┐                ┌──────────┐               ┌──────────┐     │
│  │ Service │──/metrics──────│ Scrape   │               │ SLO      │     │
│  │    A    │                │ Targets  │               │ Dashboard│     │
│  └─────────┘                │          │               │          │     │
│  ┌─────────┐                │ Recording│───PromQL────▶│ Service  │     │
│  │ Service │──/metrics──────│ Rules    │               │ Health   │     │
│  │    B    │                │          │               │ Dashboard│     │
│  └─────────┘                │ Alerting │               └──────────┘     │
│  ┌─────────┐                │ Rules    │                               │
│  │ Service │──/metrics──────│          │──────────┐                    │
│  │    C    │                └──────────┘          │                    │
│  └─────────┘                                      ▼                    │
│                                            ┌──────────────┐            │
│                                            │ AlertManager │            │
│                                            │  → PagerDuty │            │
│                                            │  → Slack     │            │
│                                            └──────────────┘            │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## SLO Definitions

### Availability SLO

| Target | Error Budget | Monthly Downtime |
|--------|--------------|------------------|
| 99.9%  | 0.1%         | 43.8 minutes     |
| 99.5%  | 0.5%         | 3.6 hours        |
| 99%    | 1%           | 7.2 hours        |

### Latency SLO

| Metric | Target | Description |
|--------|--------|-------------|
| P50    | < 100ms | 50% of requests |
| P90    | < 300ms | 90% of requests |
| P99    | < 500ms | 99% of requests |

## SLI Metrics

### HTTP Requests

```yaml
# Total requests
http_requests_total{service, method, status_code, path}

# Request duration histogram
http_request_duration_seconds_bucket{service, method, le}
```

### Recording Rules

Pre-computed metrics for efficient SLO calculations:

```yaml
# Availability (5-minute window)
sli:availability:ratio5m = success_rate / total_rate

# Error rate
sli:error:ratio5m = error_rate / total_rate

# Latency percentiles
sli:latency:p99_5m = histogram_quantile(0.99, ...)
```

## Multi-Window Burn Rate Alerts

Based on Google SRE recommendations for alerting:

### Alert Windows

| Severity | Short Window | Long Window | Burn Rate | Budget Consumed |
|----------|--------------|-------------|-----------|-----------------|
| Critical | 5m           | 1h          | 14.4x     | 2% in 1 hour    |
| Warning  | 30m          | 6h          | 6x        | 5% in 6 hours   |
| Info     | 6h           | 3d          | 1x        | 10% in 3 days   |

### Alert Formula

```
(short_window_error_rate > threshold) AND (long_window_error_rate > threshold)
```

## Installation

### Deploy via ArgoCD

```bash
# Deploy Prometheus
kubectl apply -f kubernetes/argocd/applications/prometheus.yaml

# Deploy Grafana
kubectl apply -f kubernetes/argocd/applications/grafana.yaml
```

### Manual Deployment

```bash
# Deploy Prometheus
kubectl apply -k kubernetes/prometheus/

# Deploy Grafana
kubectl apply -k kubernetes/grafana/
```

## Grafana Dashboards

### 1. SLO Overview Dashboard

Shows high-level SLO status:
- Availability gauge (target: 99.9%)
- P99 latency gauge (target: < 500ms)
- Error budget remaining
- Request rate
- Availability trend
- Error rate trend
- Latency distribution
- Burn rate chart

### 2. Service Health Dashboard

Detailed per-service metrics:
- Service status (UP/DOWN)
- Instance count
- CPU/Memory usage
- Request rate by status code
- Request rate by endpoint
- Resource usage trends

## Instrumenting Your Services

### Prometheus Client Libraries

Add metrics to your application:

```go
// Go example
import "github.com/prometheus/client_golang/prometheus"

var httpRequestsTotal = prometheus.NewCounterVec(
    prometheus.CounterOpts{
        Name: "http_requests_total",
        Help: "Total HTTP requests",
    },
    []string{"service", "method", "status_code", "path"},
)

var httpRequestDuration = prometheus.NewHistogramVec(
    prometheus.HistogramOpts{
        Name:    "http_request_duration_seconds",
        Help:    "HTTP request duration",
        Buckets: []float64{.01, .05, .1, .25, .5, 1, 2.5, 5, 10},
    },
    []string{"service", "method"},
)
```

### Service Annotations

Enable Prometheus scraping:

```yaml
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

## Accessing Dashboards

### Port Forward (Development)

```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:3000
```

### Default Credentials

- **Grafana**: admin / (set via `grafana-admin` secret)

## Alerting Configuration

### AlertManager Integration

Configure AlertManager for notifications:

```yaml
# alertmanager-config.yaml
global:
  resolve_timeout: 5m

route:
  receiver: 'slack-notifications'
  group_by: ['alertname', 'service']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h

receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/xxx'
        channel: '#alerts'
```

### PagerDuty Integration

For critical alerts:

```yaml
receivers:
  - name: 'pagerduty-critical'
    pagerduty_configs:
      - service_key: 'your-service-key'
        severity: critical
```

## Best Practices

### 1. Define Meaningful SLOs

- Start with user-facing metrics
- Set achievable targets (not 100%)
- Include error budget policy

### 2. Alert on Burn Rate, Not Symptoms

- Multi-window alerts reduce noise
- Focus on error budget consumption
- Page only when SLO is at risk

### 3. Review and Adjust

- Monthly SLO review meetings
- Adjust targets based on data
- Document incidents and budget usage

### 4. Error Budget Policy

When budget is exhausted:
1. Freeze feature releases
2. Focus on reliability work
3. Conduct incident review
4. Resume when budget recovers

## File Structure

```
kubernetes/
├── prometheus/
│   ├── base/
│   │   ├── namespace.yaml
│   │   ├── prometheus.yaml
│   │   └── kustomization.yaml
│   ├── rules/
│   │   └── slo-rules.yaml      # Recording & alerting rules
│   └── kustomization.yaml
├── grafana/
│   ├── base/
│   │   ├── namespace.yaml
│   │   ├── grafana.yaml
│   │   └── kustomization.yaml
│   ├── dashboards/
│   │   ├── slo-overview.json
│   │   └── service-health.json
│   └── kustomization.yaml
└── argocd/
    └── applications/
        ├── prometheus.yaml
        └── grafana.yaml
```

## References

- [Google SRE Book - SLOs](https://sre.google/sre-book/service-level-objectives/)
- [Google SRE Workbook - Alerting on SLOs](https://sre.google/workbook/alerting-on-slos/)
- [Prometheus Best Practices](https://prometheus.io/docs/practices/naming/)
- [Grafana Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
