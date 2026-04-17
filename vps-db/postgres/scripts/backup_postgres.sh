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
docker exec "${POSTGRES_CONTAINER_NAME}" pg_dump -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" | gzip > "${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_${POSTGRES_DB}_${TIMESTAMP}.sql.gz"
find "${BACKUP_DIR}" -type f -name "*.sql.gz" -mtime +"${BACKUP_RETENTION_DAYS}" -delete
