# Alert Configuration

Setup and configure alerts for ELK stack with Alertmanager.

## Overview

Alertmanager handles alert routing, deduplication, and notifications.

## Alertmanager Configuration

### Basic Configuration

```yaml
# alertmanager.yml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'password'

route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'slack'
  routes:
    - match:
        severity: critical
      receiver: 'slack-critical'
      continue: true
    - match:
        severity: warning
      receiver: 'slack'
    - match:
        severity: info
      receiver: 'email'

receivers:
  - name: 'slack'
    slack_configs:
      - channel: '#alerts'
        send_resolved: true
        webhook_url: 'https://hooks.slack.com/services/XXX/YYY/ZZZ'

  - name: 'slack-critical'
    slack_configs:
      - channel: '#alerts-critical'
        send_resolved: true
        webhook_url: 'https://hooks.slack.com/services/XXX/YYY/ZZZ'

  - name: 'email'
    email_configs:
      - to: 'admin@example.com'
        send_resolved: true
```

## Alert Rules

### Prometheus Alert Rules

Create `alert.rules` for system monitoring:

```yaml
groups:
  - name: system_alerts
    interval: 30s
    rules:
      # High CPU
      - alert: HighCPU
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is {{ $value }}%"

      # High Memory
      - alert: HighMemory
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is {{ $value }}%"

      # Disk Space Low
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 15
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk {{ $labels.mountpoint }} has only {{ $value }}% free"

      # Service Down
      - alert: ServiceDown
        expr: up == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "{{ $labels.job }} is down"
          description: "{{ $labels.job }} on {{ $labels.instance }} has been down for 2 minutes"

      # SSL Certificate Expiring
      - alert: SSLCertExpiring
        expr: probe_ssl_certificate_expiry_seconds < 604800  # 7 days
        for: 1h
        labels:
          severity: warning
        annotations:
          summary: "SSL certificate expiring soon"
          description: "Certificate for {{ $labels.instance }} expires in {{ $value | humanizeDuration }}"
```

## Notification Channels

### Slack

```yaml
receivers:
  - name: 'slack'
    slack_configs:
      - channel: '#alerts'
        api_url: 'https://hooks.slack.com/services/XXX/YYY/ZZZ'
        send_resolved: true
        title: '{{ if eq .Status "firing" }}:fire:{{ else }}:white_check_mark:{{ end }} {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Labels.alertname }}
          *Severity:* {{ .Labels.severity }}
          *Summary:* {{ .Annotations.summary }}
          *Description:* {{ .Annotations.description }}
          *Details:*
          {{ range .Labels.SortedPairs }} - {{ .Name }}: {{ .Value }}
          {{ end }}
          {{ end }}
```

### Telegram

```yaml
receivers:
  - name: 'telegram'
    telegram_configs:
      - bot_token: '123456789:ABCdefGHIjklMNOpqrSTUvwxyz'
        chat_id: '-100123456789'
        send_resolved: true
        message: |
          {{ if eq .Status "firing" }}🚨{{ else }}✅{{ end }} {{ .GroupLabels.alertname }}
          
          {{ range .Alerts }}
          *Severity:* {{ .Labels.severity }}
          *Summary:* {{ .Annotations.summary }}
          {{ end }}
```

### Email

```yaml
receivers:
  - name: 'email'
    email_configs:
      - to: 'admin@example.com'
        from: 'alerts@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: 'alerts@example.com'
        auth_password: 'password'
        send_resolved: true
        headers:
          subject: '{{ if eq .Status "firing" }}[CRITICAL]{{ else }}[RESOLVED]{{ end }} {{ .GroupLabels.alertname }}'
```

### Discord

```yaml
receivers:
  - name: 'discord'
    webhook_configs:
      - url: 'https://discord.com/api/webhooks/XXX/YYY'
        send_resolved: true
```

### PagerDuty

```yaml
receivers:
  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'your-pagerduty-integration-key'
        severity: critical
        send_resolved: true
```

### Webhook

```yaml
receivers:
  - name: 'webhook'
    webhook_configs:
      - url: 'http://example.com/webhook'
        send_resolved: true
```

## Alert Examples

### Error Rate Alert

```yaml
- alert: HighErrorRate
  expr: sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100 > 5
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate detected"
    description: "Error rate is {{ $value }}%"
```

### Latency Alert

```yaml
- alert: HighLatency
  expr: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le)) > 2
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High request latency"
    description: "95th percentile latency is {{ $value }}s"
```

### Disk I/O Alert

```yaml
- alert: HighDiskIO
  expr: rate(node_disk_io_time_seconds_total[5m]) * 100 > 80
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High disk I/O on {{ $labels.instance }}"
    description: "Disk I/O utilization is {{ $value }}%"
```

### Network Traffic Alert

```yaml
- alert: HighNetworkTraffic
  expr: rate(node_network_receive_bytes_total[5m]) > 100000000
  for: 10m
  labels:
    severity: info
  annotations:
    summary: "High network traffic on {{ $labels.instance }}"
    description: "Network receive rate is {{ $value | humanize }}B/s"
```

## Inhibit Rules

Prevent alert storms by inhibiting less important alerts:

```yaml
inhibit_rules:
  # Inhibit info alerts when critical is firing
  - source_match:
      severity: critical
    target_match:
      severity: info
    equal: ['alertname', 'instance']

  # Inhibit alerts from same instance
  - source_match:
      severity: critical
    target_match_re:
      severity: 'warning|info'
    equal: ['instance']
```

## Testing Alerts

### Test Webhook

```bash
# Send test alert
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[{
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning",
      "instance": "test.example.com"
    },
    "annotations": {
      "summary": "This is a test alert",
      "description": "Testing Alertmanager configuration"
    }
  }]'
```

### Check Alertmanager Status

```bash
curl http://localhost:9093/api/v1/status
```

## Troubleshooting

### Alerts Not Firing

1. Check Prometheus rules: `curl localhost:9090/api/v1/rules`
2. Check Alertmanager connectivity
3. Verify receiver configuration

### Notifications Not Sent

1. Check Alertmanager logs
2. Verify webhook URLs
3. Test with curl

### Duplicate Alerts

1. Check grouping configuration
2. Review inhibit rules
3. Configure repeat_interval
