#!/usr/bin/env bash
set -euo pipefail
echo "=== Platform Version ==="
cat ./VERSION 2>/dev/null || echo "Unknown"
echo
echo "=== Config ==="
[ -f ./config/platform.yml ] && head -n 80 ./config/platform.yml || echo "No config found."
echo
echo "=== Services ==="
ROOT="${ROOT:-/opt/vps}"
find "${ROOT}" -maxdepth 4 \( -name "docker-compose.yml" -o -name "docker-compose.yaml" \) | sort
