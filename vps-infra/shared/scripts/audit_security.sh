#!/usr/bin/env bash
set -euo pipefail
echo "=== UFW Status ==="
ufw status verbose || true
echo
echo "=== Listening Ports ==="
ss -tulpn || true
echo
echo "=== Docker Published Ports ==="
docker ps --format 'table {{.Names}}\t{{.Ports}}'
