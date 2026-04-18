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
docker exec "${MYSQL_CONTAINER_NAME}" mysqldump -uroot -p"${MYSQL_ROOT_PASSWORD}" "${MYSQL_DATABASE}" | gzip > "${BACKUP_DIR}/${BACKUP_FILE_PREFIX}_${MYSQL_DATABASE}_${TIMESTAMP}.sql.gz"
find "${BACKUP_DIR}" -type f -name "*.sql.gz" -mtime +"${BACKUP_RETENTION_DAYS}" -delete
