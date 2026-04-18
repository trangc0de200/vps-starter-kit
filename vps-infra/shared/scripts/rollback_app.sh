#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <app_dir> <commit_or_tag>"
  exit 1
fi
APP_DIR="$1"
TARGET="$2"
cd "${APP_DIR}"
git fetch origin
git checkout "${TARGET}"
docker compose up -d --build
if [ -f ./scripts/healthcheck.sh ]; then
  chmod +x ./scripts/healthcheck.sh
  ./scripts/healthcheck.sh
fi
