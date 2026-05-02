# Discord Alerts

Send alerts and notifications to Discord channels via webhooks.

## Setup

### 1. Create Discord Webhook

1. Open Discord and go to **Server Settings** > **Integrations**
2. Click **Create Webhook**
3. Name your webhook (e.g., "VPS Alerts")
4. Select channel (e.g., #alerts)
5. Click **Copy Webhook URL**

### 2. Configure

```bash
cd vps-alerting/discord

# Copy environment
cp .env.example .env

# Add webhook URL
echo "DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/XXX/YYY" >> .env
```

### 3. Test

```bash
# Send test message
./send_test.sh

# Or use the function
source send_alert.sh
discord_send "Test message" "info"
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

# With embed
./send_alert.sh --title "Service Down" --message "PostgreSQL is not responding" --field "Host:db1.example.com" --field "Error:Connection refused"
```

### Script Integration

```bash
#!/bin/bash
source send_alert.sh

# Send critical alert
discord_send "Database connection failed" "critical"

# Send warning
discord_send "Disk space running low" "warning"

# Send success
discord_send "Backup completed successfully" "success"
```

## Alert Levels

| Level | Color | Use Case |
|-------|-------|----------|
| `critical` | Red (0xFF0000) | Service down, data loss |
| `warning` | Orange (0xFFA500) | Disk/memory high, backup failed |
| `info` | Blue (0x3498DB) | General info |
| `success` | Green (0x36A64F) | Success, backup complete |

## Message Formatting

### Simple Text

```bash
discord_send "Simple message" "info"
```

### Rich Embed

```bash
#!/bin/bash
source send_alert.sh

discord_send_embed() {
    local title="$1"
    local message="$2"
    local level="${3:-info}"
    local color=$(level_color "$level")

    local payload=$(cat <<EOF
{
    "username": "VPS Alerts",
    "embeds": [{
        "title": "$title",
        "description": "$message",
        "color": $color,
        "footer": {
            "text": "VPS Alert System"
        },
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    }]
}
EOF
)

    curl -s -X POST -H "Content-Type: application/json" \
        -d "$payload" "$DISCORD_WEBHOOK_URL"
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
  --field "Error:Connection refused"
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

## Discord Embeds

Discord supports rich embeds with multiple fields:

```bash
#!/bin/bash
source send_alert.sh

discord_send_rich() {
    local title="$1"
    local message="$2"
    local level="${3:-info}"
    local color=$(level_color "$level")
    shift 3
    local fields=("$@")

    # Build fields JSON
    local fields_json=""
    for field in "${fields[@]}"; do
        local name=$(echo "$field" | cut -d: -f1)
        local value=$(echo "$field" | cut -d: -f2-)
        fields_json+=$(cat <<EOF
{
    "name": "$name",
    "value": "$value",
    "inline": true
},
EOF
)
    done

    local payload=$(cat <<EOF
{
    "username": "VPS Alerts",
    "avatar_url": "https://i.imgur.com/AfFp7pu.png",
    "embeds": [{
        "title": "$title",
        "description": "$message",
        "color": $color,
        "fields": [$fields_json],
        "footer": {
            "text": "VPS Alert System"
        },
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    }]
}
EOF
)

    curl -s -X POST -H "Content-Type: application/json" \
        -d "$payload" "$DISCORD_WEBHOOK_URL"
}
```

## Troubleshooting

### Webhook Not Working

```bash
# Test manually
curl -H "Content-Type: application/json" \
  -d '{"content":"Test message"}' \
  'https://discord.com/api/webhooks/XXX/YYY'
```

### Rate Limiting

Discord webhook rate limits:
- 30 requests per minute per webhook
- Burst up to 5 requests

## Files

```
discord/
├── send_alert.sh      # Main alert function
├── send_test.sh       # Test webhook
└── .env.example       # Environment template
```
