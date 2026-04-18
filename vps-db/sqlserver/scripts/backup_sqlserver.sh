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
docker exec "${MSSQL_CONTAINER_NAME}" /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -P "${SA_PASSWORD}" -Q "BACKUP DATABASE [${MSSQL_DATABASE}] TO DISK = N'/var/opt/mssql/backup/${BACKUP_FILE_PREFIX}_${MSSQL_DATABASE}_${TIMESTAMP}.bak' WITH INIT, COMPRESSION, CHECKSUM, STATS = 10"

find "${BACKUP_DIR}" -type f -mtime +"${BACKUP_RETENTION_DAYS}" -delete
