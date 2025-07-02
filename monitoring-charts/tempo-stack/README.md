# Tempo Stack Helm Chart

This Helm chart deploys a complete distributed tracing stack with Grafana Tempo and OpenTelemetry Collector on Kubernetes.

## Overview

The Tempo Stack includes:
- **Grafana Tempo**: Distributed tracing backend for storing and querying traces
- **OpenTelemetry Collector**: Trace collection and forwarding service

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Persistent Volume provisioner support in the underlying infrastructure (optional, for persistent storage)

## Installation

### Add the chart repository (if applicable)
```bash
helm repo add tempo-stack /path/to/monitoring-charts
helm repo update
```

### Install the chart
```bash
helm install tempo-stack ./tempo-stack -n observability --create-namespace
```

### Install with custom values
```bash
helm install tempo-stack ./tempo-stack -n observability --create-namespace -f custom-values.yaml
```

## Configuration

The following table lists the configurable parameters and their default values.

### Global Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Namespace for all resources | `observability` |

### Tempo Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tempo.enabled` | Enable Tempo deployment | `true` |
| `tempo.image.repository` | Tempo image repository | `grafana/tempo` |
| `tempo.image.tag` | Tempo image tag | `2.3.0` |
| `tempo.image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `tempo.service.name` | Tempo service name | `tempo` |
| `tempo.service.type` | Tempo service type | `ClusterIP` |
| `tempo.service.ports.otlp-grpc` | OTLP gRPC port | `4317` |
| `tempo.service.ports.otlp-http` | OTLP HTTP port | `4318` |
| `tempo.service.ports.http` | Tempo HTTP API port | `3200` |
| `tempo.storage.backend` | Storage backend (local, s3) | `local` |
| `tempo.storage.local.path` | Local storage path | `/var/tempo` |
| `tempo.retention.period` | Trace retention period | `3d` |
| `tempo.persistence.enabled` | Enable persistent storage | `true` |
| `tempo.persistence.size` | Storage size | `10Gi` |
| `tempo.resources.limits.cpu` | CPU limit | `1000m` |
| `tempo.resources.limits.memory` | Memory limit | `2Gi` |

### OpenTelemetry Collector Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `otelCollector.enabled` | Enable OpenTelemetry Collector | `true` |
| `otelCollector.image.repository` | OTEL Collector image repository | `otel/opentelemetry-collector-contrib` |
| `otelCollector.image.tag` | OTEL Collector image tag | `0.89.0` |
| `otelCollector.service.name` | OTEL Collector service name | `otel-collector` |
| `otelCollector.service.ports.otlp-grpc` | OTLP gRPC receiver port | `4317` |
| `otelCollector.service.ports.otlp-http` | OTLP HTTP receiver port | `4318` |
| `otelCollector.resources.limits.cpu` | CPU limit | `500m` |
| `otelCollector.resources.limits.memory` | Memory limit | `1Gi` |

### ServiceMonitor Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceMonitor.enabled` | Enable ServiceMonitor for Prometheus | `false` |
| `serviceMonitor.interval` | Scrape interval | `30s` |
| `serviceMonitor.scrapeTimeout` | Scrape timeout | `10s` |

## Usage

### Sending Traces

Configure your applications to send traces to the OpenTelemetry Collector:

**OTLP gRPC:**
```
otel-collector.observability.svc.cluster.local:4317
```

**OTLP HTTP:**
```
http://otel-collector.observability.svc.cluster.local:4318
```

### Querying Traces

Access Tempo's HTTP API for querying traces:
```
http://tempo.observability.svc.cluster.local:3200
```

### Grafana Integration

Add Tempo as a data source in Grafana:
- **URL:** `http://tempo.observability.svc.cluster.local:3200`
- **Type:** Tempo

## Storage Configuration

### Local Storage (Default)
The chart uses local storage by default with a persistent volume.

### S3 Storage
To use S3 storage, update your values:

```yaml
tempo:
  storage:
    backend: s3
    s3:
      bucket: "your-tempo-bucket"
      endpoint: "s3.amazonaws.com"
      region: "us-west-2"
      access_key: "your-access-key"
      secret_key: "your-secret-key"
```

## Monitoring

Enable ServiceMonitor to scrape OpenTelemetry Collector metrics:

```yaml
serviceMonitor:
  enabled: true
  interval: 30s
```

## Troubleshooting

### Check Pod Status
```bash
kubectl get pods -n observability
```

### View Logs
```bash
kubectl logs -n observability deployment/tempo-stack-tempo
kubectl logs -n observability deployment/tempo-stack-otel-collector
```

### Test Connectivity
```bash
kubectl port-forward -n observability svc/tempo 3200:3200
kubectl port-forward -n observability svc/otel-collector 4317:4317
```

## Uninstallation

```bash
helm uninstall tempo-stack -n observability
```

## Requirements

Based on the monitoring design document:
- **Retention Period**: 3 days (configurable)
- **OTLP Protocol Support**: Both gRPC and HTTP
- **Service Address**: `tempo.observability.svc.cluster.local:4317` for OTLP gRPC
- **Storage**: Configurable between local and object storage (S3)
- **Integration**: Ready for Grafana data source integration
