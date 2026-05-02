# Prometheus + Grafana Stack

Metrics collection, storage, and visualization for VPS infrastructure.

## Overview

- **Prometheus**: Time-series database and metrics collection
- **Grafana**: Dashboards and visualization
- **Alertmanager**: Alert routing and deduplication

## Quick Start

```bash
cd vps-monitoring/prometheus-grafana
docker-compose up -d
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| Prometheus | 9090 | Metrics database |
| Grafana | 3002 | Dashboards |

## Access

- **Grafana**: http://localhost:3002
  - Username: `admin`
  - Password: `changeme`

- **Prometheus**: http://localhost:9090

## Configuration

### Environment Variables

```bash
# Grafana
GRAFANA_PASSWORD=your_secure_password

# Prometheus
PROMETHEUS_RETENTION_DAYS=30
```

### Prometheus Configuration

Edit `prometheus.yml` to add scrape targets:

```yaml
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']
```

## Dashboards

### Import Dashboards

1. Go to Grafana → Dashboards → Import
2. Enter dashboard ID
3. Select Prometheus data source
4. Click Import

### Recommended Dashboards

| ID | Name | Source |
|----|------|--------|
| 1860 | Node Exporter Full | Prometheus |
| 14091 | PostgreSQL Overview | Prometheus |
| 17900 | Redis | Prometheus |
| 12430 | Docker Monitoring | Prometheus |

## Alerting

### Prometheus Alert Rules

Edit `prometheus.yml` to add alert rules:

```yaml
rule_files:
  - "alert.rules"
```

Create `alert.rules`:

```yaml
groups:
  - name: alerts
    rules:
      - alert: HighCPU
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
```

### Grafana Alerts

1. Create dashboard panel
2. Click Alert tab
3. Create alert rule
4. Configure notification channel

## Data Sources

### Prometheus

Default data source already configured in Grafana.

### Add External Prometheus

1. Go to Grafana → Configuration → Data Sources
2. Click Add data source
3. Select Prometheus
4. Enter URL: `http://prometheus:9090`
5. Click Save & Test

## Monitoring Targets

### System Metrics

Use Node Exporter:

```yaml
- job_name: 'node'
  static_configs:
    - targets: ['node-exporter:9100']
```

### Docker Metrics

Use cAdvisor:

```yaml
- job_name: 'cadvisor'
  static_configs:
    - targets: ['cadvisor:8080']
```

### PostgreSQL Metrics

Use Postgres Exporter:

```yaml
- job_name: 'postgres'
  static_configs:
    - targets: ['postgres-exporter:9187']
```

### MySQL Metrics

Use MySQL Exporter:

```yaml
- job_name: 'mysql'
  static_configs:
    - targets: ['mysql-exporter:9104']
```

### Redis Metrics

Use Redis Exporter:

```yaml
- job_name: 'redis'
  static_configs:
    - targets: ['redis-exporter:9121']
```
