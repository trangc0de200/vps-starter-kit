#!/usr/bin/env bash
# Test Alert Script - Send test alerts to all channels

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  VPS Alerting - Test All Channels"
echo "=========================================="
echo ""

# Test Slack
if [[ -f "${SCRIPT_DIR}/slack/send_alert.sh" ]]; then
    echo "Testing Slack..."
    source "${SCRIPT_DIR}/slack/send_alert.sh"
    send_slack "Test Alert" "This is a test message from VPS Alert System" "info" || true
    echo ""
fi

# Test Telegram
if [[ -f "${SCRIPT_DIR}/telegram/send_alert.sh" ]]; then
    echo "Testing Telegram..."
    source "${SCRIPT_DIR}/telegram/send_alert.sh"
    send_telegram "Test Alert" "This is a test message from VPS Alert System" "info" || true
    echo ""
fi

# Test Discord
if [[ -f "${SCRIPT_DIR}/discord/send_alert.sh" ]]; then
    echo "Testing Discord..."
    source "${SCRIPT_DIR}/discord/send_alert.sh"
    send_discord "Test Alert" "This is a test message from VPS Alert System" "info" || true
    echo ""
fi

echo "=========================================="
echo "  Test Complete"
echo "=========================================="
echo ""
echo "Check all channels for test messages."
