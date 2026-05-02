# Slack Alerts

Send alerts and notifications to Slack channels via webhooks.

## Setup

### 1. Create Slack App

1. Go to https://api.slack.com/apps
2. Click **Create New App** > **From scratch**
3. Name your app (e.g., "VPS Alerts")
4. Select your workspace
5. Click **Incoming Webhooks**
6. Enable **Activate Incoming Webhooks**
7. Click **Add New Webhook to Workspace**
8. Select channel (e.g., #alerts)
9. Copy the Webhook URL

### 2. Configure

```bash
cd vps-alerting/slack

# Copy environment
cp .env.example .env

# Add webhook URL
echo "SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/ZZZ" >> .env
```

### 3. Test

```bash
# Send test message
./send_test.sh

# Or use the function
source send_alert.sh
slack_send "Test message" "info"
```

## Usage

### Command Line

```bash
# Basic message
./send_alert.sh --message "Server is down"

# With title
./send_alert.sh --title "Alert" --message "Service unavailable"

# With level
./send_alert.sh --level critical --title "CRITICAL" --message "Database connection failed"

# With fields
./send_alert.sh \
  --title "High CPU Usage" \
  --message "CPU usage exceeded 90%" \
  --field "Host:server1.example.com" \
  --field "Value:95%" \
  --field "Time:2024-01-15 14:32:00"
```

### Script Integration

```bash
#!/bin/bash
source send_alert.sh

# Send critical alert
slack_send "Database connection failed" "critical"

# Send warning
slack_send "Disk space running low" "warning"

# Send success
slack_send "Backup completed successfully" "success"
```

### Advanced Usage

```bash
# With custom fields
slack_alert_with_fields() {
    local title="$1"
    local message="$2"
    local level="$3"
    shift 3
    
    local payload=$(cat <<EOF
{
    "attachments": [{
        "color": "$(level_color "$level")",
        "title": "$title",
        "text": "$message",
        "fields": [
            $(for field in "$@"; do echo "{\"value\": \"$field\", \"short\": true},"; done)
        ],
        "footer": "VPS Alert System",
        "ts": $(date +%s)
    }]
}
EOF
)
    curl -s -X POST -H "Content-type: application/json" \
        -d "$payload" "$SLACK_WEBHOOK_URL"
}
```

## Alert Levels

| Level | Color | Use Case |
|-------|-------|----------|
| `critical` | #FF0000 | Service down, data loss |
| `warning` | #FFA500 | Disk/memory high, backup failed |
| `info` | #808080 | General info |
| `success` | #36A64F | Success, backup complete |

## Message Formatting

### Simple Text

```bash
slack_send "Simple message" "info"
```

### With Formatting

```bash
slack_send_advanced() {
    local title="$1"
    local message="$2"
    local level="$3"
    
    local color=$(case "$level" in
        critical) echo "#FF0000" ;;
        warning) echo "#FFA500" ;;
        success) echo "#36A64F" ;;
        *) echo "#808080" ;;
    esac)
    
    local payload=$(cat <<EOF
{
    "attachments": [{
        "color": "$color",
        "title": "$title",
        "text": "$message",
        "footer": "VPS Alerting",
        "ts": $(date +%s)
    }]
}
EOF
)
    curl -s -X POST -H "Content-type: application/json" \
        -d "$payload" "$SLACK_WEBHOOK_URL"
}
```

### Block Kit (Modern Slack)

```bash
slack_send_block() {
    local title="$1"
    local message="$2"
    local level="$3"
    
    local emoji=$(case "$level" in
        critical) echo "🚨" ;;
        warning) echo "⚠️" ;;
        success) echo "✅" ;;
        *) echo "ℹ️" ;;
    esac)
    
    local payload=$(cat <<EOF
{
    "blocks": [
        {
            "type": "header",
            "text": {
                "type": "plain_text",
                "text": "$emoji $title",
                "emoji": true
            }
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "$message"
            }
        },
        {
            "type": "context",
            "elements": [
                {
                    "type": "mrkdwn",
                    "text": "Sent from VPS Alert System | $(date '+%Y-%m-%d %H:%M:%S')"
                }
            ]
        }
    ]
}
EOF
)
    curl -s -X POST -H "Content-type: application/json" \
        -d "$payload" "$SLACK_WEBHOOK_URL"
}
```

## Example Alerts

### Service Down

```bash
./send_alert.sh \
  --level critical \
  --title "🚨 Service Down" \
  --message "PostgreSQL is not responding" \
  --field "Host:db1.example.com" \
  --field "Port:5432" \
  --field "Error:Connection refused" \
  --field "Time:$(date '+%Y-%m-%d %H:%M:%S')"
```

### Backup Complete

```bash
./send_alert.sh \
  --level success \
  --title "✅ Backup Complete" \
  --message "Daily database backup finished successfully" \
  --field "Database:appdb" \
  --field "Size:245MB" \
  --field "Duration:2m 34s"
```

### SSL Expiring

```bash
./send_alert.sh \
  --level warning \
  --title "⚠️ SSL Certificate Expiring" \
  --message "Certificate for api.example.com expires in 7 days" \
  --field "Domain:api.example.com" \
  --field "Expires:2024-01-22" \
  --field "Days Left:7"
```

### High CPU

```bash
./send_alert.sh \
  --level warning \
  --title "⚠️ High CPU Usage" \
  --message "CPU usage exceeded 90% threshold" \
  --field "Host:web1.example.com" \
  --field "CPU:95%" \
  --field "Load:12.45"
```

## Troubleshooting

### Webhook URL Not Working

```bash
# Test manually
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test message"}' \
  'https://hooks.slack.com/services/XXX/YYY/ZZZ'
```

### Channel Not Found

- Ensure the webhook was created for the correct channel
- Bot needs to have permission to post to that channel

### Rate Limiting

Slack has rate limits:
- 1 message per second per channel
- 30 messages per minute

## Files

```
slack/
├── send_alert.sh      # Main alert function
├── send_test.sh       # Test webhook
└── .env.example       # Environment template
```
