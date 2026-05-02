# Netdata

Real-time performance monitoring for systems and applications.

## Overview

Netdata provides:
- Real-time CPU, memory, disk, network monitoring
- Docker container monitoring
- Application metrics
- Customizable dashboards
- Alarming and notifications

## Quick Start

```bash
cd vps-monitoring/netdata
docker-compose up -d
```

## Access

- **Netdata**: http://localhost:19999

## Features

### System Metrics
- CPU usage per core
- Memory usage
- Disk I/O
- Network traffic
- System processes

### Docker Monitoring
- Container resource usage
- Container health
- Image storage
- Network statistics

### Applications
- Web server metrics (nginx, apache)
- Database metrics (MySQL, PostgreSQL)
- Custom application metrics

## Configuration

### Environment Variables

```bash
# Network
NETDATA_PORT=19999

# Performance
NETDATA_RESERVED_MEMORY=256

# Updates
NETDATA_UPDATE=auto
```

### Adjust Memory

```yaml
environment:
  - NETDATA_RESERVED_MEMORY=512
```

## Dashboards

### Main Dashboard

Navigate to: http://localhost:19999

### Sections
- System Overview
- CPU
- Memory
- Disks
- Network
- Docker
- Applications

## Alerts

### Default Alerts

Netdata comes with pre-configured alerts for:
- CPU usage
- Memory usage
- Disk space
- Bandwidth
- Container health

### Custom Alerts

Edit `netdata.conf` or create custom health checks.

## Integration

### Prometheus

Enable Prometheus exporter:

```yaml
environment:
  - NETDATA_PROMETHEUS_EXPORTER_ENABLED=true
```

Access metrics at: http://localhost:19999/api/v1/allmetrics?format=prometheus

### Grafana

Add Netdata as a data source:

```yaml
- job_name: 'netdata'
  metrics_path: /api/v1/allmetrics
  params:
    format: ['prometheus']
  static_configs:
    - targets: ['netdata:19999']
```

## Troubleshooting

### High Memory Usage

```yaml
environment:
  - NETDATA_RESERVED_MEMORY=256
```

### Not Showing Docker Metrics

Ensure Docker socket is mounted:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

### Slow Dashboard

Reduce update frequency:
```yaml
environment:
  - NETDATA_UPDATE_EVERY=5
```
