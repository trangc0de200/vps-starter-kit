#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/opt/vps}"
SCRIPTS=(
  "${ROOT}/vps-db/postgres/scripts/backup_postgres.sh"
  "${ROOT}/vps-db/mysql/scripts/backup_mysql.sh"
  "${ROOT}/vps-db/redis/scripts/backup_redis.sh"
  "${ROOT}/vps-db/sqlserver/scripts/backup_sqlserver.sh"
)

for script in "${SCRIPTS[@]}"; do
  if [ -x "${script}" ]; then
    echo "Running ${script}"
    "${script}"
  else
    echo "Skipping missing or non-executable script: ${script}"
  fi
done
