#!/usr/bin/env bash
# Slack Alert Script

set -euo pipefail

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "${SCRIPT_DIR}/.env" ]] && source "${SCRIPT_DIR}/.env"

# Default values
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
SLACK_CHANNEL="${SLACK_CHANNEL:-#alerts}"
SLACK_USERNAME="${SLACK_USERNAME:-VPS Alert Bot}"

# Colors
RED='\x1b[31m'
ORANGE='\x1b[33m'
GREEN='\x1b[32m'
BLUE='\x1b[34m'
NC='\x1b[0m'

usage() {
    cat << EOF
Slack Alert Script

Usage: $0 [OPTIONS]

Options:
    -t, --title TITLE       Alert title
    -m, --message MESSAGE   Alert message
    -l, --level LEVEL       Alert level (critical|warning|info|success)
    -c, --channel CHANNEL   Slack channel (default: #alerts)
    -f, --field KEY:VALUE   Additional fields (can be repeated)
    -h, --help             Show this help

Examples:
    $0 --title "Server Down" --message "Web server not responding" --level critical
    $0 -t "High CPU" -m "CPU at 95%" -l warning -f "Host:server1"
EOF
    exit 1
}

level_color() {
    case "$1" in
        critical) echo "#FF0000" ;;
        warning)  echo "#FFA500" ;;
        success)  echo "#36A64F" ;;
        info|*)   echo "#808080" ;;
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

send_slack() {
    local title="$1"
    local message="$2"
    local level="${3:-info}"
    shift 3
    local fields=("$@")

    if [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        echo -e "${RED}Error: SLACK_WEBHOOK_URL not set${NC}"
        return 1
    fi

    local color=$(level_color "$level")
    local emoji=$(level_emoji "$level")

    # Build fields JSON
    local fields_json=""
    if [[ ${#fields[@]} -gt 0 ]]; then
        fields_json=","
        for field in "${fields[@]}"; do
            local key=$(echo "$field" | cut -d: -f1)
            local value=$(echo "$field" | cut -d: -f2-)
            fields_json+="{\"title\":\"$key\",\"value\":\"$value\",\"short\":true},"
        done
        fields_json="${fields_json%,}"
    fi

    local payload=$(cat <<EOF
{
    "channel": "$SLACK_CHANNEL",
    "username": "$SLACK_USERNAME",
    "attachments": [{
        "color": "$color",
        "title": "$emoji $title",
        "text": "$message",
        "fields": [$fields_json],
        "footer": "VPS Alert System",
        "ts": $(date +%s)
    }]
}
EOF
)

    curl -s -X POST -H "Content-type: application/json" \
        --data-urlencode "payload=${payload}" \
        "$SLACK_WEBHOOK_URL" | grep -q '"ok":true' || \
        curl -s -X POST -H "Content-type: application/json" \
            -d "$payload" \
            "$SLACK_WEBHOOK_URL" > /dev/null

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
        -c|--channel) SLACK_CHANNEL="$2"; shift 2 ;;
        -f|--field) FIELDS+=("$2"); shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Send if we have a message
if [[ -n "$MESSAGE" ]]; then
    send_slack "$TITLE" "$MESSAGE" "$LEVEL" "${FIELDS[@]}"
else
    usage
fi
