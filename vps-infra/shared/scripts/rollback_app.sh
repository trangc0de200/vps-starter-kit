#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$1"
TARGET="$2"
cd "${APP_DIR}"
git fetch origin
git checkout "${TARGET}"
docker compose up -d --build
if [ -f ./scripts/healthcheck.sh ]; then ./scripts/healthcheck.sh; fi
