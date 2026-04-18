#!/usr/bin/env bash
set -euo pipefail
if [ -z "${1:-}" ]; then
  echo "Usage: $0 <commit-hash-or-tag>"
  exit 1
fi
TARGET="$1"
git fetch origin
git checkout "${TARGET}"
docker compose up -d --build
if [ -f ./healthcheck.sh ]; then
  ./healthcheck.sh production
fi
