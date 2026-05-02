# VPS Monitoring Stack

Production-ready monitoring and observability solution with metrics, logs, and alerting.

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MONITORING STACK                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │   Netdata    │  │  Prometheus  │  │ Uptime Kuma  │             │
│  │  Real-time   │  │   Metrics    │  │    Uptime    │             │
│  │   Metrics    │  │  Collection  │  │  Monitoring   │             │
│  │  Port 19999  │  │  Port 9090   │  │   Port 3001  │             │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘             │
│         │                  │                                        │
│         │                  ▼                                        │
│         │         ┌──────────────┐                                  │
│         │         │   Grafana    │                                  │
│         │         │ Dashboards   │                                  │
│         │         │ Port 3002    │                                  │
│         │         └──────────────┘                                  │
│         │                                                            │
│  ┌──────┴──────────────────────────────────────────┐               │
│  │              LOGGING & ALERTING                   │               │
│  ├──────────────────────────────────────────────────┤               │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────────┐    │               │
│  │  │Elastic  │  │ Kibana  │  │Alertmanager │    │               │
│  │  │search   │  │ Logs UI │  │  Routing   │    │               │
│  │  │Port 9200│  │Port 5601│  │ Port 9093  │    │               │
│  │  └─────────┘  └─────────┘  └─────────────┘    │               │
│  └──────────────────────────────────────────────────┘               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Components

### Metrics & Dashboards

| Component | Description | Port | Use Case |
|-----------|-------------|------|----------|
| [Netdata](netdata/) | Real-time monitoring | 19999 | System metrics |
| [Prometheus](prometheus-grafana/) | Time-series DB | 9090 | App metrics |
| [Grafana](prometheus-grafana/) | Dashboards | 3002 | Visualization |

### Uptime & Health

| Component | Description | Port | Use Case |
|-----------|-------------|------|----------|
| [Uptime Kuma](uptime-kuma/) | Uptime monitoring | 3001 | HTTP/TCP checks |
| [Alertmanager](elk/alertmanager/) | Alert routing | 9093 | Notifications |

### Logging

| Component | Description | Port | Use Case |
|-----------|-------------|------|----------|
| [Elasticsearch](elk/) | Log storage | 9200 | Search & store |
| [Kibana](elk/) | Log UI | 5601 | Visualization |
| [Logstash](elk/) | Log processing | - | Parsing |
| [Fluentd](elk/) | Log collection | 24224 | Daemon |

## Quick Start

### 1. Start Monitoring Stack

```bash
# Prometheus + Grafana
cd vps-monitoring/prometheus-grafana
docker-compose up -d

# Netdata
cd vps-monitoring/netdata
docker-compose up -d

# Uptime Kuma
cd vps-monitoring/uptime-kuma
docker-compose up -d
```

### 2. Start Logging Stack

```bash
cd vps-monitoring/elk
cp .env.example .env
docker-compose up -d
```

### 3. Access Services

| Service | URL | Default Login |
|---------|-----|---------------|
| Grafana | http://localhost:3002 | admin/changeme |
| Prometheus | http://localhost:9090 | - |
| Netdata | http://localhost:19999 | - |
| Kibana | http://localhost:5601 | elastic/changeme |
| Elasticsearch | http://localhost:9200 | elastic/changeme |
| Alertmanager | http://localhost:9093 | - |
| Uptime Kuma | http://localhost:3001 | - |

## Feature Comparison

| Feature | Netdata | Prometheus+Grafana | Uptime Kuma | ELK |
|---------|---------|-------------------|-------------|-----|
| Real-time metrics | ✅ | ❌ | ❌ | ❌ |
| Historical data | Limited | ✅ | Limited | ✅ |
| Custom dashboards | ✅ | ✅ | ❌ | ✅ |
| Log aggregation | ❌ | ❌ | ❌ | ✅ |
| HTTP monitoring | ✅ | ❌ | ✅ | ❌ |
| Alert routing | ✅ | ✅ | ✅ | ✅ |
| Log search | ❌ | ❌ | ❌ | ✅ |
| Auto-discovery | ✅ | ✅ | ❌ | ❌ |

## Architecture

### Metrics Flow

```
Application → Exporter (node, postgres, mysql) → Prometheus → Grafana
                                                            ↓
                                                    Alertmanager → Slack/Email
```

### Logging Flow

```
Application → Fluentd/Filebeat → Elasticsearch ← Kibana
                                             ↓
                                      Alertmanager → Slack/Email
```

## Prometheus Targets

| Target | Endpoint | Metrics |
|--------|----------|---------|
| Node Exporter | :9100 | System metrics |
| cAdvisor | :8080 | Docker metrics |
| Postgres Exporter | :9187 | PostgreSQL metrics |
| MySQL Exporter | :9104 | MySQL metrics |
| Redis Exporter | :9121 | Redis metrics |

## Dashboards

### Pre-configured Dashboards

| Dashboard | Source | Metrics |
|-----------|--------|---------|
| System Overview | Netdata | CPU, RAM, Disk, Network |
| Docker Overview | cAdvisor | Containers, Images |
| Database Performance | Exporters | Queries, Connections |
| Application Metrics | Custom | Business metrics |

### Import Dashboards

1. Go to Grafana → Dashboards → Import
2. Search for dashboard ID
3. Select Prometheus data source
4. Configure and save

Popular Dashboard IDs:
- 1860: Node Exporter Full
- 17900: Redis Dashboard
- 14091: PostgreSQL Overview

## Alerting

### Prometheus Alerts

Alert rules defined in `prometheus.yml`:

```yaml
groups:
  - name: alerts
    rules:
      - alert: HighCPU
        expr: cpu_usage > 80
        for: 5m
        labels:
          severity: warning
```

### Grafana Alerts

1. Create dashboard panel
2. Click Alert tab
3. Configure conditions
4. Add notification channel

### Uptime Kuma

1. Add Monitor
2. Select type (HTTP/TCP/Ping)
3. Configure notifications
4. Set check interval

## Integration

### With VPS Alerting

```bash
# Slack
SLACK_WEBHOOK_URL=https://hooks.slack.com/...

# Telegram
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHAT_ID=...
```

### With VPS Backup

```bash
# Backup monitoring data
./scripts/backup-monitoring.sh
```

## Configuration

### Prometheus

See [prometheus-grafana/prometheus.yml](prometheus-grafana/prometheus.yml)

### Grafana

```bash
GF_SECURITY_ADMIN_PASSWORD=your_secure_password
GF_SERVER_ROOT_URL=https://monitoring.example.com
```

### Elasticsearch

```bash
ES_JAVA_OPTS=-Xms2g -Xmx2g
ES_HEAP_SIZE=2g
```

## Maintenance

### Backup

```bash
# Grafana dashboards
docker run --rm -v grafana_data:/data -v $(pwd):/backup alpine \
    tar czf /backup/grafana_backup.tar.gz -C /data .

# Elasticsearch indices
curl -X POST "localhost:9200/_snapshot/backup" -d '{"type":"fs"}'
```

### Cleanup

```bash
# Remove old Prometheus data
docker exec prometheus promtool tsdb clean --keep=30d

# Elasticsearch index lifecycle
curl -X PUT "localhost:9200/_ilm/policy/30-day-retention" \
    -H 'Content-Type: application/json' \
    -d '{"policy":{"phases":{"delete":{"min_age":"30d"}}}'
```

## Troubleshooting

### Prometheus Not Scraping

```bash
# Check targets
curl localhost:9090/api/v1/targets

# Check logs
docker-compose logs prometheus
```

### Grafana Login Issues

```bash
# Reset admin password
docker exec -it grafana grafana-cli admin reset-admin-password newpassword
```

### Elasticsearch Out of Memory

```bash
# Increase heap
ES_JAVA_OPTS=-Xms4g -Xmx4g
```

## Documentation

- [Prometheus + Grafana](prometheus-grafana/README.md)
- [Netdata](netdata/README.md)
- [Uptime Kuma](uptime-kuma/README.md)
- [ELK Stack](elk/README.md)
- [Alert Configuration](elk/ALERTS.md)
- [ELK Configuration](elk/CONFIG.md)

## Security

### Best Practices

1. **Restrict access**: Use reverse proxy with auth
2. **Enable SSL**: Use HTTPS for all services
3. **Strong passwords**: Change defaults immediately
4. **Network isolation**: Use Docker networks
5. **Firewall**: Allow only necessary ports

### Firewall

```bash
# Allow only from internal network
ufw allow from 192.168.1.0/24 to any port 3002  # Grafana
ufw allow from 192.168.1.0/24 to any port 9090  # Prometheus
```

## Performance Tuning

### Prometheus

```yaml
storage:
  tsdb:
    retention.time: 30d
    retention.size: 50GB
```

### Elasticsearch

```bash
# Increase heap
ES_JAVA_OPTS=-Xms8g -Xmx8g

# Disable swapping
bootstrap.memory_lock: true
```

## License

MIT
