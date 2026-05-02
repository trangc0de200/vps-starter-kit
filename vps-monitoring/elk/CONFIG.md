# ELK Configuration Guide

## Overview

This ELK Stack provides centralized logging and alerting for your VPS infrastructure.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Your VPS                             │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐     │
│  │ App 1   │  │ App 2   │  │ Database│  │  Nginx  │     │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘     │
│       │            │            │            │          │
│       └────────────┴─────┬──────┴────────────┘          │
│                          │                              │
│                    ┌─────▼─────┐                        │
│                    │  Fluentd  │                        │
│                    │ (Collector)│                        │
│                    └─────┬─────┘                        │
│                          │                              │
│       ┌──────────────────┼──────────────────┐         │
│       │                  │                  │          │
│  ┌────▼────┐       ┌────▼────┐        ┌────▼────┐    │
│  │  Kafka   │       │Elastic  │        │Alertmgr  │    │
│  │ (Buffer) │       │search   │        │(Alerts) │    │
│  └─────────┘       └────┬────┘        └────┬────┘    │
│                        │                  │          │
│                   ┌────▼────┐             │          │
│                   │  Kibana │             │          │
│                   │(Dashboard)│◀──────────┘          │
│                   └─────────┘                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Configuration

### Environment Variables

Edit `.env`:

```bash
# Elasticsearch
ELASTICSEARCH_HEAP_SIZE=512m  # Increase for production
ELASTICSEARCH_PASSWORD=your_secure_password

# Retention
LOG_RETENTION_DAYS=30          # How long to keep logs

# Alerting
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
ALERTMANAGER_SMTP_AUTH_PASSWORD=your_email_password
```

### Alertmanager

#### Slack Setup

1. Create a Slack app at https://api.slack.com
2. Enable Incoming Webhooks
3. Copy webhook URL to `.env`

#### Email Setup

```yaml
# In alertmanager/alertmanager.yml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@yourdomain.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'
```

#### PagerDuty Setup

1. Create PagerDuty service
2. Copy Integration Key to `PAGERDUTY_ROUTING_KEY`

### Fluentd

#### Adding Log Sources

**Docker JSON logs** (add to your docker-compose.yml):
```yaml
services:
  your-app:
    logging:
      driver: fluentd
      options:
        fluentd-address: fluentd:24224
        tag: app.your-service
```

**Direct HTTP**:
```bash
curl -X POST http://fluentd:9880/app.access \
  -H 'Content-Type: application/json' \
  -d '{"message": "User logged in", "user_id": 123}'
```

### Elasticsearch

#### Index Lifecycle Management

Create ILM policy for automatic rollover:

```bash
curl -X PUT "localhost:9200/_ilm/policy/fluentd-policy" \
  -u elastic:changeme \
  -H 'Content-Type: application/json' \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_size": "50gb",
              "max_age": "7d"
            }
          }
        },
        "delete": {
          "min_age": "30d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'
```

### Kibana

#### Creating Index Patterns

1. Access Kibana: http://localhost:5601
2. Go to Stack Management → Index Patterns
3. Create pattern: `fluentd-*`
4. Select `@timestamp` as time field
5. Create additional patterns for:
   - `nginx-*`
   - `app-*`
   - `docker-*`

## Monitoring Metrics

### Key Metrics to Track

| Metric | Description | Threshold |
|--------|-------------|-----------|
| Log rate | Logs/minute | >10000 = concerning |
| Error rate | % of logs containing "error" | >5% = warning |
| Disk usage | ES disk usage | >80% = warning |
| Memory | ES heap usage | >85% = warning |

### Kibana Dashboards

Recommended dashboards:
1. **Log Overview**: Total logs, by source, by severity
2. **Error Analysis**: Error trends, common errors
3. **Service Health**: Logs per service, response times
4. **Alert History**: Fired alerts, response times

## Troubleshooting

### Elasticsearch won't start

```bash
# Check logs
docker-compose logs elasticsearch

# Check disk space
df -h

# Increase memory limit in .env
ELASTICSEARCH_HEAP_SIZE=1g
```

### Fluentd not receiving logs

```bash
# Check if Fluentd is running
docker-compose ps fluentd

# Test connection
telnet fluentd 24224

# Check logs
docker-compose logs fluentd
```

### Kibana can't connect to Elasticsearch

```bash
# Reset password
docker exec elasticsearch bin/elasticsearch-setup-passwords auto

# Update password in Kibana env
```

## Performance Tuning

### Elasticsearch

```bash
# Increase heap (in .env)
ELASTICSEARCH_HEAP_SIZE=2g

# In production, set to 50% of RAM, max 32GB
```

### Fluentd

```bash
# Increase buffer size for high throughput
# In fluentd.conf:
buffer_chunk_limit 256KB
queue_limit_length 1024
```

## Backup & Restore

### Backup
```bash
./elk.sh backup
```

### Restore
```bash
./elk.sh restore backups/elk_backup_20240101_120000.tar.gz
```
