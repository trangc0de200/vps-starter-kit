#!/usr/bin/env bash
set -euo pipefail
ROOT="${ROOT:-/opt/vps}"
for s in "${ROOT}/vps-db/postgres/scripts/backup_postgres.sh" "${ROOT}/vps-db/mysql/scripts/backup_mysql.sh" "${ROOT}/vps-db/redis/scripts/backup_redis.sh" "${ROOT}/vps-db/sqlserver/scripts/backup_sqlserver.sh"; do
  [ -x "$s" ] && "$s"
done
