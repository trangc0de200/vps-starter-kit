#!/usr/bin/env bash
set -euo pipefail

if [ -f ../.env.production ]; then
  set -a
  source ../.env.production
  set +a
fi

URL="${HEALTHCHECK_URL:-http://127.0.0.1}"
for i in $(seq 1 10); do
  if curl -fsS "${URL}" >/dev/null; then
    echo "Health check passed."
    exit 0
  fi
  echo "Health check failed, retry ${i}/10..."
  sleep 5
done

echo "Health check failed."
exit 1
