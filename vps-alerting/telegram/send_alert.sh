#!/usr/bin/env bash
# Telegram Alert Script

set -euo pipefail

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/.env" ]] && source "${SCRIPT_DIR}/.env"

# Default values
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
TELEGRAM_PARSE_MODE="${TELEGRAM_PARSE_MODE:-HTML}"

usage() {
    cat << EOF
Telegram Alert Script

Usage: $0 [OPTIONS]

Options:
    -t, --title TITLE       Alert title
    -m, --message MESSAGE   Alert message
    -l, --level LEVEL       Alert level (critical|warning|info|success)
    -p, --parse MODE        Parse mode (HTML|Markdown)
    -h, --help             Show this help

Examples:
    $0 --title "Server Down" --message "Web server not responding" --level critical
    $0 -t "High CPU" -m "CPU at 95%" -l warning
EOF
    exit 1
}

level_emoji() {
    case "$1" in
        critical) echo "🚨" ;;
        warning)  echo "⚠️" ;;
        success)  echo "✅" ;;
        info|*)   echo "ℹ️" ;;
    esac
}

send_telegram() {
    local title="$1"
    local message="$2"
    local level="${3:-info}"

    if [[ -z "$TELEGRAM_BOT_TOKEN" ]] || [[ -z "$TELEGRAM_CHAT_ID" ]]; then
        echo "Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set"
        return 1
    fi

    local emoji=$(level_emoji "$level")

    # Format message
    local text="$emoji <b>$title</b>%0A%0A$message%0A%0A"
    text+="<i>Sent: $(date '+%Y-%m-%d %H:%M:%S')</i>"

    local response=$(curl -s -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "text=${text}" \
        -d "parse_mode=HTML")

    if echo "$response" | grep -q '"ok":true'; then
        echo -e "\e[32mAlert sent successfully\e[0m"
    else
        echo "Error sending alert: $response"
        return 1
    fi
}

# Parse arguments
TITLE=""
MESSAGE=""
LEVEL="info"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--title) TITLE="$2"; shift 2 ;;
        -m|--message) MESSAGE="$2"; shift 2 ;;
        -l|--level) LEVEL="$2"; shift 2 ;;
        -p|--parse) TELEGRAM_PARSE_MODE="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Send if we have a message
if [[ -n "$MESSAGE" ]]; then
    send_telegram "$TITLE" "$MESSAGE" "$LEVEL"
else
    usage
fi
