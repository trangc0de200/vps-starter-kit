# Telegram Alerts

Send alerts and notifications to Telegram via Bot API.

## Setup

### 1. Create Telegram Bot

1. Open Telegram and search for **@BotFather**
2. Send `/newbot`
3. Enter bot name (e.g., "VPS Alerts Bot")
4. Enter username (e.g., "vps_alerts_bot")
5. Copy the Bot Token: `123456789:ABCdefGHIjklMNOpqrSTUvwxyz`

### 2. Get Chat ID

**Option A: Direct Message**
1. Start a chat with your bot
2. Send any message to the bot
3. Visit: `https://api.telegram.org/bot<TOKEN>/getUpdates`
4. Find `"chat":{"id":123456789,...}` in the response

**Option B: Channel/Group**
1. Add bot to your channel/group
2. Make bot an admin
3. Send `/start` in the chat
4. Visit: `https://api.telegram.org/bot<TOKEN>/getUpdates`
5. Find the chat ID (will be negative for groups)

### 3. Configure

```bash
cd vps-alerting/telegram

# Copy environment
cp .env.example .env

# Add bot token and chat ID
echo "TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrSTUvwxyz" >> .env
echo "TELEGRAM_CHAT_ID=123456789" >> .env
```

### 4. Test

```bash
# Send test message
./send_test.sh

# Or use the function
source send_alert.sh
telegram_send "Test message" "info"
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

# With HTML formatting
./send_alert.sh --title "Server Stats" --message "<b>CPU:</b> 85%" --parse HTML
```

### Script Integration

```bash
#!/bin/bash
source send_alert.sh

# Send critical alert
telegram_send "Database connection failed" "critical"

# Send with custom message
telegram_send_message "Custom message" "warning"

# Send with HTML
telegram_send_html "<b>Bold</b> and <i>italic</i>" "info"
```

### Advanced Formatting

```bash
#!/bin/bash
source send_alert.sh

# Rich message with fields
telegram_send_rich() {
    local title="$1"
    local message="$2"
    local level="$3"
    shift 3
    
    local emoji=$(case "$level" in
        critical) echo "🚨" ;;
        warning) echo "⚠️" ;;
        success) echo "✅" ;;
        *) echo "ℹ️" ;;
    esac)
    
    local text="<b>$emoji $title</b>%0A%0A"
    text+="$message%0A%0A"
    
    for field in "$@"; do
        text+="$field%0A"
    done
    
    text+="%0A<i>$(date '+%Y-%m-%d %H:%M:%S')</i>"
    
    telegram_send "$text" "$level"
}

# Usage
telegram_send_rich \
    "Service Down" \
    "PostgreSQL is not responding" \
    "critical" \
    "Host: db1.example.com" \
    "Port: 5432" \
    "Error: Connection refused"
```

## Alert Levels

| Level | Emoji | Color | Use Case |
|-------|-------|-------|----------|
| `critical` | 🚨 | Red | Service down, data loss |
| `warning` | ⚠️ | Orange | Disk/memory high |
| `info` | ℹ️ | Blue | General info |
| `success` | ✅ | Green | Success notifications |

## HTML Formatting

Telegram supports HTML formatting:

| Tag | Description | Example |
|-----|-------------|---------|
| `<b>` | Bold | `<b>text</b>` |
| `<i>` | Italic | `<i>text</i>` |
| `<u>` | Underline | `<u>text</u>` |
| `<code>` | Monospace | `<code>text</code>` |
| `<pre>` | Preformatted | `<pre>text</pre>` |
| `<a>` | Link | `<a href="url">text</a>` |

## Example Alerts

### Service Down

```bash
./send_alert.sh \
  --level critical \
  --title "🚨 Service Down" \
  --message "PostgreSQL is not responding" \
  --parse HTML
```

### Backup Complete

```bash
./send_alert.sh \
  --level success \
  --title "✅ Backup Complete" \
  --message "Daily database backup finished" \
  --parse HTML
```

### High Memory

```bash
./send_alert.sh \
  --level warning \
  --title "⚠️ High Memory Usage" \
  --message "<b>Memory:</b> 87% used
<b>Host:</b> web1.example.com
<b>Load:</b> 8.45" \
  --parse HTML
```

### SSL Expiring

```bash
./send_alert.sh \
  --level warning \
  --title "⚠️ SSL Certificate Expiring" \
  --message "Certificate expires in 7 days
<b>Domain:</b> api.example.com
<b>Expires:</b> 2024-01-22" \
  --parse HTML
```

## Keyboard Buttons

Add inline keyboard buttons:

```bash
#!/bin/bash
source send_alert.sh

# Message with buttons
telegram_send_with_buttons() {
    local message="$1"
    local level="$2"
    
    local emoji=$(case "$level" in
        critical) echo "🚨" ;;
        warning) echo "⚠️" ;;
        *) echo "ℹ️" ;;
    esac)
    
    local payload=$(cat <<EOF
{
    "chat_id": "$TELEGRAM_CHAT_ID",
    "text": "$emoji $message",
    "parse_mode": "HTML",
    "reply_markup": {
        "inline_keyboard": [[
            {"text": "View Dashboard", "url": "https://grafana.example.com"},
            {"text": "View Logs", "url": "https://logs.example.com"}
        ],[
            {"text": "Acknowledge", "callback_data": "ack"},
            {"text": "Dismiss", "callback_data": "dismiss"}
        ]]
    }
}
EOF
)
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "$payload"
}
```

## Troubleshooting

### Bot Not Responding

```bash
# Check bot token
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getMe"

# Should return:
# {"ok":true,"result":{"id":123456789,"is_bot":true,...}}
```

### Chat ID Issues

```bash
# Get updates (after sending message to bot)
curl "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/getUpdates"

# Look for:
# "chat":{"id":123456789,"type":"private"}  <- Private chat
# "chat":{"id":-100123456789,"type":"channel"}  <- Channel/Group
```

### Message Too Long

Telegram has a 4096 character limit per message.
Split long messages:

```bash
split_message() {
    local text="$1"
    local maxlen=4000
    
    if [ ${#text} -gt $maxlen ]; then
        echo "${text:0:$maxlen}"
        echo "...(truncated)"
    else
        echo "$text"
    fi
}
```

## Rate Limits

- 30 messages per second to a group
- ~20-30 messages per minute to a user
- Bot can send to groups without limit if added as admin

## Files

```
telegram/
├── send_alert.sh      # Main alert function
├── send_test.sh       # Test bot
└── .env.example       # Environment template
```
