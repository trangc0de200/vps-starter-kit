#!/usr/bin/env bash
# Backup All Databases Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/../logs/backup-all.log"

# Load environment
if [[ -f "${SCRIPT_DIR}/../.env" ]]; then
    source "${SCRIPT_DIR}/../.env"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] $message" | tee -a "${LOG_FILE}"
}

info() { log "${BLUE}[INFO]${NC} $*"; }
success() { log "${GREEN}[SUCCESS]${NC} $*"; }
warn() { log "${YELLOW}[WARN]${NC} $*"; }
error() { log "${RED}[ERROR]${NC} $*"; }

# Create log directory
mkdir -p "${SCRIPT_DIR}/../logs"

# Configuration
BACKUP_DIR="${SCRIPT_DIR}/../backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Export passwords
export PGPASSWORD="${POSTGRES_PASSWORD:-change_me_strong_password}"
export MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-change_me_root_password}"

backup_postgres() {
    info "Starting PostgreSQL backup..."
    
    local backup_name="postgres_${TIMESTAMP}"
    local target_dir="${BACKUP_DIR}/postgres"
    
    mkdir -p "${target_dir}"
    
    # Check if container is running
    if ! docker ps | grep -q postgres; then
        warn "PostgreSQL container not running, skipping..."
        return 0
    fi
    
    # Get databases
    local databases=$(docker exec postgres psql -U postgres -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;" 2>/dev/null)
    
    for db in $databases; do
        db=$(echo "$db" | xargs)
        [[ -z "$db" ]] && continue
        
        info "Dumping database: ${db}"
        
        if docker exec postgres pg_dump -U postgres -Fc "${db}" > "${target_dir}/${backup_name}_${db}.dump" 2>/dev/null; then
            gzip "${target_dir}/${backup_name}_${db}.dump"
            sha256sum "${target_dir}/${backup_name}_${db}.dump.gz" > "${target_dir}/${backup_name}_${db}.dump.gz.sha256"
            success "Backed up: ${db}"
        else
            error "Failed to backup: ${db}"
        fi
    done
}

backup_mysql() {
    info "Starting MySQL backup..."
    
    local backup_name="mysql_${TIMESTAMP}"
    local target_dir="${BACKUP_DIR}/mysql"
    
    mkdir -p "${target_dir}"
    
    # Check if container is running
    if ! docker ps | grep -q mysql; then
        warn "MySQL container not running, skipping..."
        return 0
    fi
    
    # Get databases
    local databases=$(docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -t -e "SHOW DATABASES;" 2>/dev/null | grep -v Database | grep -v information_schema | grep -v mysql | grep -v performance_schema | grep -v sys)
    
    for db in $databases; do
        db=$(echo "$db" | xargs)
        [[ -z "$db" ]] && continue
        
        info "Dumping database: ${db}"
        
        if docker exec mysql mysqldump -u root -p"${MYSQL_ROOT_PASSWORD}" \
            --single-transaction --routines --triggers --events \
            "${db}" > "${target_dir}/${backup_name}_${db}.sql" 2>/dev/null; then
            gzip "${target_dir}/${backup_name}_${db}.sql"
            sha256sum "${target_dir}/${backup_name}_${db}.sql.gz" > "${target_dir}/${backup_name}_${db}.sql.gz.sha256"
            success "Backed up: ${db}"
        else
            error "Failed to backup: ${db}"
        fi
    done
}

backup_redis() {
    info "Starting Redis backup..."
    
    local backup_name="redis_${TIMESTAMP}"
    local target_dir="${BACKUP_DIR}/redis"
    
    mkdir -p "${target_dir}"
    
    # Check if container is running
    if ! docker ps | grep -q redis; then
        warn "Redis container not running, skipping..."
        return 0
    fi
    
    # Trigger BGSAVE
    info "Triggering Redis background save..."
    docker exec redis redis-cli -a "${REDIS_PASSWORD:-}" BGSAVE 2>/dev/null || true
    
    # Wait for completion
    sleep 2
    
    # Copy dump file
    docker cp "redis:/data/dump.rdb" "${target_dir}/${backup_name}.rdb" 2>/dev/null
    
    if [[ -f "${target_dir}/${backup_name}.rdb" ]]; then
        gzip "${target_dir}/${backup_name}.rdb"
        sha256sum "${target_dir}/${backup_name}.rdb.gz" > "${target_dir}/${backup_name}.rdb.gz.sha256"
        success "Redis backup completed"
    else
        error "Failed to backup Redis"
    fi
}

cleanup_old() {
    info "Cleaning up backups older than ${RETENTION_DAYS} days..."
    
    find "${BACKUP_DIR}" -name "*.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
    find "${BACKUP_DIR}" -name "*.sha256" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
    
    success "Cleanup completed"
}

show_summary() {
    info "Backup Summary"
    echo ""
    echo "Backups location: ${BACKUP_DIR}"
    echo ""
    echo "PostgreSQL backups:"
    ls -lh "${BACKUP_DIR}/postgres"/*.gz 2>/dev/null | tail -5 || echo "  No backups"
    echo ""
    echo "MySQL backups:"
    ls -lh "${BACKUP_DIR}/mysql"/*.gz 2>/dev/null | tail -5 || echo "  No backups"
    echo ""
    echo "Redis backups:"
    ls -lh "${BACKUP_DIR}/redis"/*.gz 2>/dev/null | tail -5 || echo "  No backups"
}

# Main
main() {
    log "═══════════════════════════════════════════════════════════"
    log "Starting backup job at $(date)"
    log "═══════════════════════════════════════════════════════════"
    
    # Create backup directory
    mkdir -p "${BACKUP_DIR}"
    
    # Run backups
    backup_postgres
    backup_mysql
    backup_redis
    
    # Cleanup
    cleanup_old
    
    # Summary
    show_summary
    
    log "═══════════════════════════════════════════════════════════"
    log "Backup job completed at $(date)"
    log "═══════════════════════════════════════════════════════════"
}

# Execute
main "$@"
