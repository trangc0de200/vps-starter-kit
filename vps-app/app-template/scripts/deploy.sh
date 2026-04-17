#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${APP_DIR}"

git fetch origin
git reset --hard origin/main

if [ -f ./scripts/backup.sh ]; then
  chmod +x ./scripts/backup.sh
  ./scripts/backup.sh
fi

docker compose up -d --build

if [ -f ./scripts/migrate.sh ]; then
  chmod +x ./scripts/migrate.sh
  ./scripts/migrate.sh
fi

if [ -f ./scripts/healthcheck.sh ]; then
  chmod +x ./scripts/healthcheck.sh
  ./scripts/healthcheck.sh
fi
