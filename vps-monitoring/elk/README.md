# ELK Stack + Alertmanager

Centralized logging, search, and alerting for VPS infrastructure.

## Overview

- **Elasticsearch**: Log storage and search
- **Kibana**: Log visualization
- **Logstash**: Log processing
- **Fluentd**: Log collection
- **Alertmanager**: Alert routing

## Quick Start

```bash
cd vps-monitoring/elk
cp .env.example .env
docker-compose up -d
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| Elasticsearch | 9200 | Search engine |
| Kibana | 5601 | Web UI |
| Logstash | 5044 | Log processing |
| Fluentd | 24224 | Log collection |
| Alertmanager | 9093 | Alert routing |

## Access

- **Elasticsearch**: http://localhost:9200
  - User: `elastic`
  - Password: `changeme`

- **Kibana**: http://localhost:5601
  - User: `elastic`
  - Password: `changeme`

- **Alertmanager**: http://localhost:9093

## Configuration

### Environment Variables

```bash
# Elasticsearch
ELASTIC_PASSWORD=changeme_strong_password
ES_JAVA_OPTS=-Xms2g -Xmx2g

# Kibana
KIBANA_HOST=elasticsearch

# Network
NETWORK_SUBNET=172.31.0.0/16
```

## Log Sources

### Docker Logs

Configure Fluentd logging driver:

```yaml
# In docker-compose.yml
logging:
  driver: fluentd
  options:
    fluentd-address: fluentd:24224
    tag: docker.{{.Name}}
```

### Application Logs

Send logs via HTTP:

```bash
curl -X POST http://localhost:9880/myapp \
  -d '{"message":"Error occurred","level":"error","service":"myapp"}'
```

### File Logs

Mount log files to Fluentd:

```yaml
fluentd:
  volumes:
    - /var/log:/var/log:ro
```

## Kibana Setup

### 1. Create Index Pattern

1. Go to http://localhost:5601
2. Stack Management → Index Patterns → Create index pattern
3. Enter pattern: `fluentd-*`
4. Select `@timestamp` as time field
5. Click Create

### 2. Discover Logs

1. Go to Discover
2. Select index pattern
3. View and search logs

### 3. Create Dashboard

1. Go to Visualize
2. Create new visualization
3. Save to Dashboard

## Search Examples

### Basic Search

```
level:error
service:api
message:"connection failed"
```

### Time Range

```
@timestamp:[now-1h TO now]
@timestamp:[2024-01-01 TO 2024-01-31]
```

### Complex Queries

```
level:error AND (service:api OR service:web)
NOT level:debug
message:/regex pattern/
```

## Alerting

### Alertmanager Configuration

See [ALERTS.md](ALERTS.md) for detailed setup.

### Alert Types

- High error rate
- Service down
- Disk space low
- SSL certificate expiring

## Retention

### Elasticsearch ILM

Configure index lifecycle management:

```bash
# Create ILM policy
curl -X PUT "localhost:9200/_ilm/policy/30-day-retention" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_age": "7d",
              "max_size": "50gb"
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

## Backup

### Snapshot to S3

```bash
# Configure repository
curl -X PUT "localhost:9200/_snapshot/backup" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "s3",
    "settings": {
      "bucket": "my-backups",
      "region": "us-east-1"
    }
  }'

# Create snapshot
curl -X PUT "localhost:9200/_snapshot/backup/snapshot_1"
```

## Troubleshooting

### Elasticsearch Won't Start

```bash
# Check logs
docker-compose logs elasticsearch

# Increase memory
ES_JAVA_OPTS=-Xms4g -Xmx4g
```

### Kibana Can't Connect

```bash
# Check Elasticsearch
curl localhost:9200

# Verify Kibana config
docker-compose logs kibana
```

### No Logs Appearing

1. Check Fluentd logs: `docker-compose logs fluentd`
2. Verify log source configuration
3. Check Elasticsearch connectivity from Fluentd

## Maintenance

### Clear Old Data

```bash
# Delete old indices
curl -X DELETE "localhost:9200/fluentd-2024.01.*"

# Force merge
curl -X POST "localhost:9200/fluentd-*/_forcemerge?only_expunge_deletes=true"
```

### Reindex

```bash
# Create new index with new settings
curl -X PUT "localhost:9200/fluentd-new"

# Reindex
curl -X POST "localhost:9200/_reindex" \
  -H "Content-Type: application/json" \
  -d '{
    "source": {"index": "fluentd-old"},
    "dest": {"index": "fluentd-new"}
  }'
```

## Security

### Enable SSL

```yaml
# In elasticsearch.yml
xpack.security.http.ssl.enabled: true
xpack.security.transport.ssl.enabled: true
```

### Network Policy

```yaml
# Restrict to internal network
services:
  elasticsearch:
    networks:
      monitoring_network:
        ipv4_address: 172.31.0.10
```

## Performance

### Increase Resources

```bash
# Elasticsearch
ES_JAVA_OPTS=-Xms8g -Xmx8g

# More replicas
PUT /fluentd-*/_settings
{"number_of_replicas": 1}
```
