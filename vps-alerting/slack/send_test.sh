#!/usr/bin/env bash
# Slack Test Alert

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/send_alert.sh"

echo "Sending test alert to Slack..."

send_slack "Test Alert" "This is a test message from VPS Alert System" "info"

echo ""
echo "Check your Slack channel #${SLACK_CHANNEL:-alerts}"
