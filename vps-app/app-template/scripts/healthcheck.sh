#!/usr/bin/env bash
set -euo pipefail
TARGET_ENV="${1:-production}"
URL="${HEALTHCHECK_URL:-http://127.0.0.1}"
for i in $(seq 1 10); do
  if curl -fsS "${URL}" >/dev/null; then echo "Health check passed."; exit 0; fi
  sleep 5
done
echo "Health check failed."
exit 1
