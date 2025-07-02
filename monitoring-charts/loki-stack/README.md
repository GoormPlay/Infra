# Loki Stack Helm Chart

This Helm chart deploys a complete logging stack with Loki and Fluent Bit for log collection and storage, designed according to the monitoring design document specifications.

## Overview

This chart includes:
- **Loki**: Log aggregation system for storing and querying logs
- **Fluent Bit**: Lightweight log processor and forwarder deployed as DaemonSet

## Features

- **Log Retention**: Configurable retention period (default: 7 days as per monitoring design)
- **Structured Logging**: JSON log parsing and trace_id extraction
- **Kubernetes Integration**: Automatic metadata enrichment for container logs
- **High Performance**: Optimized for container log collection with minimal resource usage
- **Scalable Storage**: Support for local and object storage backends

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Persistent storage (if persistence is enabled)

### Install the Chart

```bash
# Add the chart repository (if applicable)
helm repo add monitoring-charts ./monitoring-charts

# Install the chart
helm install loki-stack monitoring-charts/loki-stack \
  --namespace observability \
  --create-namespace
```

### Custom Installation

```bash
# Install with custom values
helm install loki-stack ./loki-stack \
  --namespace observability \
  --create-namespace \
  --set loki.config.storage.retention_period=14d \
  --set loki.persistence.size=20Gi
```

## Configuration

### Key Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.namespace` | Target namespace | `observability` |
| `loki.enabled` | Enable Loki deployment | `true` |
| `loki.config.storage.retention_period` | Log retention period | `7d` |
| `loki.service.port` | Loki service port | `3100` |
| `loki.persistence.enabled` | Enable persistent storage | `true` |
| `loki.persistence.size` | Storage size | `10Gi` |
| `fluentbit.enabled` | Enable Fluent Bit DaemonSet | `true` |
| `fluentbit.resources.limits.memory` | Fluent Bit memory limit | `256Mi` |

### Loki Configuration

The Loki configuration follows the monitoring design document specifications:

- **Retention Period**: 7 days (configurable via `loki.config.storage.retention_period`)
- **Service Address**: `loki.observability.svc.cluster.local:3100`
- **Storage**: BoltDB shipper with filesystem backend (configurable)
- **Ingestion Limits**: Optimized for container log ingestion

### Fluent Bit Configuration

Fluent Bit is configured to:

- Collect container logs from `/var/log/containers/*.log`
- Parse JSON logs and extract structured fields
- Enrich logs with Kubernetes metadata
- Extract `trace_id` for distributed tracing correlation
- Send logs to Loki with proper labels

## Usage

### Accessing Loki

1. **Port Forward** (for testing):
   ```bash
   kubectl port-forward -n observability svc/loki 3100:3100
   curl http://localhost:3100/ready
   ```

2. **Within Cluster**:
   ```
   http://loki.observability.svc.cluster.local:3100
   ```

### LogQL Query Examples

```logql
# All logs from fluent-bit
{job="fluent-bit"}

# Logs with trace_id (for distributed tracing)
{job="fluent-bit"} | json | trace_id != ""

# Error logs only
{job="fluent-bit"} | json | level="ERROR"

# Logs from specific namespace
{kubernetes_namespace_name="observability"}

# Logs from specific pod
{kubernetes_pod_name=~"my-app-.*"}
```

### Grafana Integration

To integrate with Grafana:

1. Add Loki as a data source:
   - URL: `http://loki.observability.svc.cluster.local:3100`
   - Access: Server (default)

2. Create log panels using LogQL queries
3. Use trace_id for correlation with distributed tracing

## Monitoring and Observability

### Health Checks

- **Loki**: `/ready` and `/metrics` endpoints
- **Fluent Bit**: `/` and `/api/v1/health` endpoints

### Metrics

Both Loki and Fluent Bit expose Prometheus metrics:
- Loki metrics: `http://loki:3100/metrics`
- Fluent Bit metrics: `http://fluent-bit:2020/api/v1/metrics/prometheus`

## Troubleshooting

### Common Issues

1. **Fluent Bit not collecting logs**:
   ```bash
   kubectl logs -n observability daemonset/loki-stack-fluent-bit
   ```

2. **Loki storage issues**:
   ```bash
   kubectl logs -n observability deployment/loki-stack-loki
   kubectl describe pvc -n observability
   ```

3. **High memory usage**:
   - Adjust `fluentbit.resources.limits.memory`
   - Tune `loki.config.limits_config.ingestion_rate_mb`

### Log Collection Verification

```bash
# Check Fluent Bit status
kubectl get pods -n observability -l app.kubernetes.io/name=fluent-bit

# Check Loki ingestion
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={job="fluent-bit"}' | jq
```

## Upgrading

```bash
# Upgrade the chart
helm upgrade loki-stack ./loki-stack \
  --namespace observability
```

## Uninstalling

```bash
# Uninstall the chart
helm uninstall loki-stack --namespace observability

# Clean up PVCs (if needed)
kubectl delete pvc -n observability -l app.kubernetes.io/name=loki
```

## Architecture

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────┐
│   Container     │    │  Fluent Bit  │    │    Loki     │
│     Logs        │───▶│  (DaemonSet) │───▶│  (Storage)  │
│ (stdout/stderr) │    │              │    │             │
└─────────────────┘    └──────────────┘    └─────────────┘
                              │                    │
                              ▼                    ▼
                       ┌──────────────┐    ┌─────────────┐
                       │  Kubernetes  │    │   Grafana   │
                       │   Metadata   │    │ (Querying)  │
                       └──────────────┘    └─────────────┘
```

## Contributing

This chart is part of the unified observability stack. For issues or improvements:

1. Check the monitoring design document for requirements
2. Test changes with the complete observability stack
3. Ensure compatibility with Prometheus and Tempo components

## License

This chart is part of the internal monitoring infrastructure.
