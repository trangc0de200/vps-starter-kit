#!/usr/bin/env bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP_DIR="${BASE_DIR}/backups"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
cd "${BASE_DIR}"
set -a
source .env
set +a
mkdir -p "${BACKUP_DIR}"
docker exec "${REDIS_CONTAINER_NAME}" redis-cli -a "${REDIS_PASSWORD}" SAVE
if docker exec "${REDIS_CONTAINER_NAME}" test -f /data/dump.rdb; then
  docker cp "${REDIS_CONTAINER_NAME}:/data/dump.rdb" "${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_${TIMESTAMP}.rdb"
fi
find "${BACKUP_DIR}" -type f -name "*.rdb" -mtime +"${BACKUP_RETENTION_DAYS}" -delete
