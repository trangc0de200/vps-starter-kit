#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_ENV="${1:-production}"
TARGET_BRANCH="${2:-}"

cd "${APP_DIR}"

if [ "${TARGET_ENV}" = "staging" ]; then
  ENV_FILE=".env.staging"
else
  ENV_FILE=".env.production"
fi

if [ -f "${ENV_FILE}" ]; then
  set -a
  source "${ENV_FILE}"
  set +a
fi

if [ -z "${TARGET_BRANCH}" ]; then
  TARGET_BRANCH="${DEPLOY_BRANCH:-main}"
fi

git fetch origin
git reset --hard "origin/${TARGET_BRANCH}"

if [ -f ./scripts/backup.sh ]; then
  chmod +x ./scripts/backup.sh
  ./scripts/backup.sh
fi

docker compose up -d --build

if [ -f ./scripts/migrate.sh ]; then
  chmod +x ./scripts/migrate.sh
  ./scripts/migrate.sh "${TARGET_ENV}"
fi

if [ -f ./scripts/healthcheck.sh ]; then
  chmod +x ./scripts/healthcheck.sh
  ./scripts/healthcheck.sh "${TARGET_ENV}"
fi
