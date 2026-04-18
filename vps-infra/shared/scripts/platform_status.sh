#!/usr/bin/env bash
set -euo pipefail
echo "=== Platform Version ==="
cat ./VERSION 2>/dev/null || echo "Unknown"
echo
echo "=== Config ==="
[ -f ./config/platform.yml ] && head -n 120 ./config/platform.yml || echo "No config found."
