# VPS Alerting System

Centralized alerting system for monitoring and notifications across the VPS platform.

## Overview

The alerting system provides real-time notifications for:

- **System Health**: CPU, memory, disk usage
- **Container Status**: Service up/down, restart loops
- **SSL Certificates**: Expiration warnings
- **Backup Status**: Success/failure notifications
- **Security Alerts**: Failed logins, port scans
- **Application Errors**: Error rates, response times

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Alert Sources                             │
├─────────────────────────────────────────────────────────────┤
│  Prometheus │ Grafana │ Healthchecks │ Custom Scripts        │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                   Alert Manager                              │
│                   (Alertmanager)                             │
└────────────────────────────┬────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│    Slack      │    │   Telegram    │    │    Discord    │
│   Channel     │    │     Bot       │    │    Webhook    │
└───────────────┘    └───────────────┘    └───────────────┘
```

## Quick Start

### 1. Configure Alerting

```bash
cd vps-alerting

# Copy environment template
cp .env.example .env

# Edit with your webhook URLs
nano .env
```

### 2. Test Alerts

```bash
# Test Slack
./slack/send_test.sh

# Test Telegram
./telegram/send_test.sh
```

### 3. Set Up Monitoring

See [docs/ALERTING.md](../docs/ALERTING.md) for integration with Prometheus/Grafana.

## Alert Channels

| Channel | Setup | Use Case |
|---------|-------|----------|
| [Slack](slack/) | Webhook URL | Team notifications |
| [Telegram](telegram/) | Bot Token | Real-time alerts |
| [Discord](discord/) | Webhook URL | Gaming/Community |

## Alert Types

### Critical (P1)

- Service down
- Disk full (>95%)
- Memory exhausted
- SSL certificate expired

### Warning (P2)

- Disk high (>85%)
- Memory high (>80%)
- SSL expiring soon
- Backup failed

### Info (P3)

- Service restarted
- Backup completed
- SSL renewed

## Usage

### Send Custom Alert

```bash
# Slack
./slack/send_alert.sh --level critical --title "Service Down" --message "API server is not responding"

# Telegram
./telegram/send_alert.sh --level warning --title "High CPU" --message "CPU usage exceeded 90%"

# Discord
./discord/send_alert.sh --level info --title "Backup Complete" --message "Daily backup finished successfully"
```

### Alert Levels

| Level | Color | Icon | Action |
|-------|-------|------|--------|
| `critical` | Red | 🚨 | Immediate action required |
| `warning` | Orange | ⚠️ | Action within hours |
| `info` | Blue | ℹ️ | Informational |
| `success` | Green | ✅ | Success notification |

## Environment Variables

```bash
# Slack
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/ZZZ
SLACK_CHANNEL=#alerts
SLACK_USERNAME=VPS Bot

# Telegram
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrSTUvwxyz
TELEGRAM_CHAT_ID=-100123456789
TELEGRAM_PARSE_MODE=HTML

# Discord
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/XXX/YYY
DISCORD_USERNAME=VPS Alerts

# Alert Configuration
ALERT_FROM_EMAIL=alerts@example.com
ALERT_RATE_LIMIT=60  # seconds between same alert
ALERT_COOLDOWN=300   # seconds before repeat alert
```

## Integration

### Prometheus Alertmanager

```yaml
# alertmanager.yml
receivers:
  - name: 'slack'
    slack_configs:
      - webhook_url: '${SLACK_WEBHOOK_URL}'
        channel: '#alerts'
        severity: critical

  - name: 'telegram'
    telegram_configs:
      - bot_token: '${TELEGRAM_BOT_TOKEN}'
        chat_id: '${TELEGRAM_CHAT_ID}'
```

### Healthchecks.io

```bash
# Ping on success
curl https://hc-ping.com/UUID/start

# Fail notification
curl -F "failure_message=Backup failed" https://hc-ping.com/UUID/fail
```

### Grafana Alerts

See [docs/ALERTING.md](../docs/ALERTING.md) for Grafana notification setup.

## Best Practices

### Alert Design

1. **Be specific**: Include affected service and metric
2. **Be actionable**: Clear next steps
3. **Be concise**: Short, readable messages
4. **Include context**: Timestamp, severity, affected users

### Alert Examples

**Good Alert:**
```
🚨 [CRITICAL] Database Connection Failed

Service: postgres-primary
Host: db1.example.com
Error: Connection refused (111)
Time: 2024-01-15 14:32:01 UTC

Action: Check if PostgreSQL is running
```

**Bad Alert:**
```
Error
```

### Rate Limiting

Set rate limits to avoid alert fatigue:

```bash
# In .env
ALERT_RATE_LIMIT=60      # Max 1 alert per type per minute
ALERT_COOLDOWN=300       # Wait 5 min before repeat
```

## Troubleshooting

### Slack Not Working

```bash
# Test webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  "$SLACK_WEBHOOK_URL"
```

### Telegram Not Working

```bash
# Test bot
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"

# Get updates
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates"
```

### Discord Not Working

```bash
# Test webhook
curl -H "Content-Type: application/json" \
  -d '{"content":"Test"}' \
  "$DISCORD_WEBHOOK_URL"
```

## Documentation

- [Slack Alerts](slack/README.md)
- [Telegram Alerts](telegram/README.md)
- [Discord Alerts](discord/README.md)
- [Alerting Setup](../docs/ALERTING.md)
