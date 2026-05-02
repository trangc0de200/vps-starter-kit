#!/bin/bash
# MySQL Backup Script

set -euo pipefail

# Configuration
BACKUP_DIR="/backups"
MYSQL_HOST="${MYSQL_HOST:-mysql}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_DATABASE="${MYSQL_DATABASE:-appdb}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="mysql_${MYSQL_DATABASE}_${TIMESTAMP}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting MySQL backup..."

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Perform backup
log "Dumping database: ${MYSQL_DATABASE}"
mysqldump -h "${MYSQL_HOST}" \
    -P "${MYSQL_PORT}" \
    -u "${MYSQL_USER}" \
    -p"${MYSQL_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --master-data=2 \
    --flush-logs \
    "${MYSQL_DATABASE}" > "${BACKUP_DIR}/${BACKUP_NAME}.sql"

# Compress
log "Compressing backup..."
gzip "${BACKUP_DIR}/${BACKUP_NAME}.sql"

# Calculate checksum
log "Calculating checksum..."
sha256sum "${BACKUP_NAME}.sql.gz" > "${BACKUP_DIR}/${BACKUP_NAME}.sql.gz.sha256"

# Cleanup old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "mysql_*.sql.gz" -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "mysql_*.sha256" -mtime +${RETENTION_DAYS} -delete

# List backups
log "Current backups:"
ls -lh "${BACKUP_DIR}"/mysql_*.sql.gz 2>/dev/null || echo "No backups found"

log "Backup completed successfully!"
