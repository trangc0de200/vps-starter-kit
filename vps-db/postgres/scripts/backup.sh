#!/bin/bash
# PostgreSQL Backup Script

set -euo pipefail

# Configuration
BACKUP_DIR="/backups"
PGHOST="${PGHOST:-postgres}"
PGUSER="${POSTGRES_USER:-postgres}"
PGDATABASE="${POSTGRES_DB:-appdb}"
PGPASSWORD="${POSTGRES_PASSWORD}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Export password
export PGPASSWORD

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="postgres_${PGDATABASE}_${TIMESTAMP}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting PostgreSQL backup..."

# Create backup directory
mkdir -p "${BACKUP_DIR}"

# Perform backup
log "Dumping database: ${PGDATABASE}"
pg_dump -h "${PGHOST}" -U "${PGUSER}" -d "${PGDATABASE}" -Fc -f "${BACKUP_DIR}/${BACKUP_NAME}.dump"

# Compress
log "Compressing backup..."
gzip "${BACKUP_DIR}/${BACKUP_NAME}.dump"

# Calculate checksum
log "Calculating checksum..."
sha256sum "${BACKUP_NAME}.dump.gz" > "${BACKUP_DIR}/${BACKUP_NAME}.dump.gz.sha256"

# Cleanup old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "postgres_*.dump.gz" -mtime +${RETENTION_DAYS} -delete
find "${BACKUP_DIR}" -name "postgres_*.sha256" -mtime +${RETENTION_DAYS} -delete

# List backups
log "Current backups:"
ls -lh "${BACKUP_DIR}"/postgres_*.dump.gz 2>/dev/null || echo "No backups found"

log "Backup completed successfully!"
