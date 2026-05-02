#!/usr/bin/env bash
# Discord Alert Script

set -euo pipefail

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/.env" ]] && source "${SCRIPT_DIR}/.env"

# Default values
DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-}"
DISCORD_USERNAME="${DISCORD_USERNAME:-VPS Alerts}"
DISCORD_AVATAR_URL="${DISCORD_AVATAR_URL:-}"

# Colors
RED='\x1b[31m'
ORANGE='\x1b[33m'
GREEN='\x1b[32m'
BLUE='\x1b[34m'
NC='\x1b[0m'

usage() {
    cat << EOF
Discord Alert Script

Usage: $0 [OPTIONS]

Options:
    -t, --title TITLE       Alert title
    -m, --message MESSAGE   Alert message
    -l, --level LEVEL       Alert level (critical|warning|info|success)
    -f, --field KEY:VALUE  Additional fields (can be repeated)
    -h, --help             Show this help

Examples:
    $0 --title "Server Down" --message "Web server not responding" --level critical
    $0 -t "High CPU" -m "CPU at 95%" -l warning -f "Host:server1"
EOF
    exit 1
}

level_color() {
    case "$1" in
        critical) echo "15158332" ;;  # Red
        warning)  echo "16744448" ;;  # Orange
        success)  echo "3066993"  ;;  # Green
        info|*)   echo "3447003"  ;;  # Blue
    esac
}

level_emoji() {
    case "$1" in
        critical) echo "🚨" ;;
        warning)  echo "⚠️" ;;
        success)  echo "✅" ;;
        info|*)   echo "ℹ️" ;;
    esac
}

send_discord() {
    local title="$1"
    local message="$2"
    local level="${3:-info}"
    shift 3
    local fields=("$@")

    if [[ -z "$DISCORD_WEBHOOK_URL" ]]; then
        echo -e "${RED}Error: DISCORD_WEBHOOK_URL not set${NC}"
        return 1
    fi

    local color=$(level_color "$level")
    local emoji=$(level_emoji "$level")

    # Build fields JSON
    local fields_json=""
    if [[ ${#fields[@]} -gt 0 ]]; then
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
        fields_json="${fields_json%,}"
    fi

    # Build payload
    local payload="{\"username\":\"$DISCORD_USERNAME\",\"embeds\":[{\"title\":\"$emoji $title\",\"description\":\"$message\",\"color\":$color,\"fields\":[$fields_json],\"footer\":{\"text\":\"VPS Alert System\"},\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}]}"

    curl -s -X POST -H "Content-Type: application/json" \
        -d "$payload" \
        "$DISCORD_WEBHOOK_URL" > /dev/null

    echo -e "${GREEN}Alert sent successfully${NC}"
}

# Parse arguments
TITLE=""
MESSAGE=""
LEVEL="info"
FIELDS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--title) TITLE="$2"; shift 2 ;;
        -m|--message) MESSAGE="$2"; shift 2 ;;
        -l|--level) LEVEL="$2"; shift 2 ;;
        -f|--field) FIELDS+=("$2"); shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Send if we have a message
if [[ -n "$MESSAGE" ]]; then
    send_discord "$TITLE" "$MESSAGE" "$LEVEL" "${FIELDS[@]}"
else
    usage
fi
