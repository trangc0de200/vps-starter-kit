#!/bin/bash
# Redis Backup Script

set -euo pipefail

# Configuration
BACKUP_DIR="/backups"
REDIS_DATA_DIR="/data"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="redis_${TIMESTAMP}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting Redis backup..."

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Trigger BGSAVE
log "Triggering background save..."
redis-cli -a "${REDIS_PASSWORD}" BGSAVE || true

# Wait for BGSAVE to complete
while [ "$(redis-cli -a "${REDIS_PASSWORD}" LASTSAVE)" == "$(redis-cli -a "${REDIS_PASSWORD}" LASTSAVE)" ]; do
    sleep 1
done

log "Copying RDB file..."
cp "${REDIS_DATA_DIR}/dump.rdb" "${BACKUP_DIR}/${BACKUP_NAME}.rdb"

# Copy AOF if exists
if [ -f "${REDIS_DATA_DIR}/appendonly.aof" ]; then
    log "Copying AOF file..."
    cp "${REDIS_DATA_DIR}/appendonly.aof" "${BACKUP_DIR}/${BACKUP_NAME}.aof"
fi

# Compress
log "Compressing backup..."
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
    -C "${BACKUP_DIR}" \
    "${BACKUP_NAME}.rdb" \
    "${BACKUP_NAME}.aof" 2>/dev/null || \
    tar -czf "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" \
    -C "${BACKUP_DIR}" \
    "${BACKUP_NAME}.rdb"

# Calculate checksum
log "Calculating checksum..."
sha256sum "${BACKUP_NAME}.tar.gz" > "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz.sha256"

# Cleanup temp files
rm -f "${BACKUP_DIR}/${BACKUP_NAME}.rdb"
rm -f "${BACKUP_DIR}/${BACKUP_NAME}.aof"

# Cleanup old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "redis_*.tar.gz" -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "redis_*.sha256" -mtime +${RETENTION_DAYS} -delete

# List backups
log "Current backups:"
ls -lh "${BACKUP_DIR}"/redis_*.tar.gz 2>/dev/null || echo "No backups found"

log "Backup completed successfully!"
