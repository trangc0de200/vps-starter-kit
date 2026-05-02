#!/usr/bin/env bash
# Discord Test Alert

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/send_alert.sh"

echo "Sending test alert to Discord..."

send_discord "Test Alert" "This is a test message from VPS Alert System" "info"

echo ""
echo "Check your Discord channel"
