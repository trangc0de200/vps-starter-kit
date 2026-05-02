#!/usr/bin/env bash
# Telegram Test Alert

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/send_alert.sh"

echo "Sending test alert to Telegram..."

send_telegram "Test Alert" "This is a test message from VPS Alert System" "info"

echo ""
echo "Check your Telegram bot"
