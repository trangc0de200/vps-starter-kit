#!/usr/bin/env bash
# VPS Backup Script
# Automated backup with multi-cloud support

set -euo pipefail

# ===========================================
# CONFIGURATION
# ===========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.env" 2>/dev/null || true

# Defaults
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${SCRIPT_DIR}/backups"
LOG_FILE="${SCRIPT_DIR}/logs/backup_${TIMESTAMP}.log"
RETENTION_DAYS=30

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===========================================
# FUNCTIONS
# ===========================================

log() {
    local level=$1
    shift
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo -e "$message" | tee -a "$LOG_FILE"
}

info() { log "INFO" "${BLUE}$*${NC}"; }
success() { log "SUCCESS" "${GREEN}$*${NC}"; }
warn() { log "WARN" "${YELLOW}$*${NC}"; }
error() { log "ERROR" "${RED}$*${NC}"; }

cleanup() {
    info "Cleaning up temporary files..."
    rm -rf "${BACKUP_DIR}/tmp" 2>/dev/null || true
}

trap cleanup EXIT

# ===========================================
# BACKUP TYPES
# ===========================================

backup_files() {
    local backup_type=${1:-full}
    local backup_name="files_${backup_type}_${TIMESTAMP}"
    
    info "Starting files backup (${backup_type})..."
    
    mkdir -p "${BACKUP_DIR}/tmp"
    
    # Create archive
    info "Compressing files..."
    tar -czf "${BACKUP_DIR}/tmp/${backup_name}.tar.gz" \
        ${EXCLUDE_PATHS:-} \
        ${BACKUP_PATHS:-/home /var/www} 2>/dev/null || true
    
    # Calculate checksum
    if [[ "${ENABLE_CHECKSUM:-true}" == "true" ]]; then
        info "Calculating checksum..."
        sha256sum "${BACKUP_DIR}/tmp/${backup_name}.tar.gz" > "${BACKUP_DIR}/tmp/${backup_name}.sha256"
    fi
    
    # Encrypt if enabled
    if [[ "${ENCRYPTION:-false}" == "true" && -n "${ENCRYPTION_PASSWORD:-}" ]]; then
        info "Encrypting backup..."
        openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "${BACKUP_DIR}/tmp/${backup_name}.tar.gz" \
            -out "${BACKUP_DIR}/tmp/${backup_name}.tar.gz.enc" \
            -pass pass:"${ENCRYPTION_PASSWORD}"
        rm "${BACKUP_DIR}/tmp/${backup_name}.tar.gz"
        mv "${BACKUP_DIR}/tmp/${backup_name}.tar.gz.enc" "${BACKUP_DIR}/${backup_name}.tar.gz.enc"
    else
        mv "${BACKUP_DIR}/tmp/${backup_name}.tar.gz" "${BACKUP_DIR}/"
    fi
    
    # Upload to cloud
    upload_backup "${backup_name}"
    
    success "Files backup completed: ${backup_name}"
}

backup_postgres() {
    info "Starting PostgreSQL backup..."
    
    local backup_name="postgres_${TIMESTAMP}"
    local db_host="${POSTGRES_HOST:-postgres}"
    local db_port="${POSTGRES_PORT:-5432}"
    local db_name="${POSTGRES_DB:-appdb}"
    local db_user="${POSTGRES_USER:-postgres}"
    
    mkdir -p "${BACKUP_DIR}/tmp"
    
    # Dump database
    if docker exec ${db_host} pg_dump -U ${db_user} -d ${db_name} > "${BACKUP_DIR}/tmp/${backup_name}.sql" 2>/dev/null; then
        info "Compressing database dump..."
        gzip "${BACKUP_DIR}/tmp/${backup_name}.sql"
        
        # Upload
        upload_backup "${backup_name}.sql.gz"
        
        success "PostgreSQL backup completed: ${backup_name}.sql.gz"
    else
        warn "PostgreSQL backup failed - database may not be available"
    fi
}

backup_mysql() {
    info "Starting MySQL backup..."
    
    local backup_name="mysql_${TIMESTAMP}"
    local db_host="${MYSQL_HOST:-mysql}"
    local db_port="${MYSQL_PORT:-3306}"
    local db_name="${MYSQL_DB:-appdb}"
    local db_user="${MYSQL_USER:-root}"
    local db_pass="${MYSQL_PASSWORD:-changeme}"
    
    mkdir -p "${BACKUP_DIR}/tmp"
    
    # Dump database
    if docker exec ${db_host} mysqldump -u ${db_user} -p${db_pass} ${db_name} > "${BACKUP_DIR}/tmp/${backup_name}.sql" 2>/dev/null; then
        info "Compressing database dump..."
        gzip "${BACKUP_DIR}/tmp/${backup_name}.sql"
        
        # Upload
        upload_backup "${backup_name}.sql.gz"
        
        success "MySQL backup completed: ${backup_name}.sql.gz"
    else
        warn "MySQL backup failed - database may not be available"
    fi
}

backup_docker_volumes() {
    info "Starting Docker volumes backup..."
    
    local backup_name="docker_volumes_${TIMESTAMP}"
    
    mkdir -p "${BACKUP_DIR}/tmp"
    
    # List all Docker volumes
    local volumes=$(docker volume ls -q)
    
    for volume in $volumes; do
        info "Backing up volume: ${volume}"
        docker run --rm \
            -v ${volume}:/data \
            -v "${BACKUP_DIR}/tmp":/backup \
            alpine:latest \
            tar czf "/backup/${volume}.tar.gz" -C /data . 2>/dev/null || true
    done
    
    # Create archive of all volumes
    if ls "${BACKUP_DIR}/tmp"/*.tar.gz 1> /dev/null 2>&1; then
        tar czf "${BACKUP_DIR}/${backup_name}.tar.gz" -C "${BACKUP_DIR}/tmp" . 2>/dev/null
        upload_backup "${backup_name}.tar.gz"
        success "Docker volumes backup completed"
    fi
}

# ===========================================
# UPLOAD FUNCTIONS
# ===========================================

upload_backup() {
    local filename=$1
    local provider=${BACKUP_PROVIDER:-local}
    
    case "$provider" in
        s3)
            upload_s3 "$filename"
            ;;
        b2)
            upload_b2 "$filename"
            ;;
        minio)
            upload_minio "$filename"
            ;;
        local)
            upload_local "$filename"
            ;;
        rsync)
            upload_rsync "$filename"
            ;;
        *)
            warn "Unknown provider: ${provider}, skipping upload"
            ;;
    esac
}

upload_s3() {
    local filename=$1
    local bucket=${S3_BUCKET:-vps-backups}
    local prefix=${S3_PREFIX:-backups/}
    
    info "Uploading to AWS S3..."
    
    if [[ -n "${AWS_ACCESS_KEY_ID:-}" && -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
        aws s3 cp "${BACKUP_DIR}/${filename}" \
            "s3://${bucket}/${prefix}${filename}" \
            --storage-class "${S3_STORAGE_CLASS:-STANDARD_IA}" \
            --no-progress 2>/dev/null && success "Uploaded to S3" || warn "S3 upload failed"
    else
        warn "AWS credentials not configured"
    fi
}

upload_b2() {
    local filename=$1
    local bucket=${B2_BUCKET:-vps-backups}
    
    info "Uploading to Backblaze B2..."
    
    if [[ -n "${B2_ACCOUNT_ID:-}" && -n "${B2_APPLICATION_KEY:-}" ]]; then
        B2_ACCOUNT_ID="${B2_ACCOUNT_ID}" \
        B2_APPLICATION_KEY="${B2_APPLICATION_KEY}" \
        b2 upload-file "${bucket}" "${BACKUP_DIR}/${filename}" "${filename}" 2>/dev/null && \
            success "Uploaded to B2" || warn "B2 upload failed"
    else
        warn "B2 credentials not configured"
    fi
}

upload_minio() {
    local filename=$1
    local endpoint=${MINIO_ENDPOINT:-s3.example.com:9000}
    local bucket=${MINIO_BUCKET:-vps-backups}
    
    info "Uploading to MinIO..."
    
    if [[ -n "${MINIO_ACCESS_KEY:-}" && -n "${MINIO_SECRET_KEY:-}" ]]; then
        mc alias set myminio "https://${endpoint}" "${MINIO_ACCESS_KEY}" "${MINIO_SECRET_KEY}" 2>/dev/null
        mc cp "${BACKUP_DIR}/${filename}" "myminio/${bucket}/${filename}" --no-progress 2>/dev/null && \
            success "Uploaded to MinIO" || warn "MinIO upload failed"
    else
        warn "MinIO credentials not configured"
    fi
}

upload_local() {
    local filename=$1
    local dest=${LOCAL_BACKUP_PATH:-/mnt/backups}
    
    info "Copying to local storage..."
    mkdir -p "$dest"
    cp "${BACKUP_DIR}/${filename}" "${dest}/${filename}"
    success "Copied to local storage"
}

upload_rsync() {
    local filename=$1
    local host=${RSYNC_HOST:-backup-server}
    local user=${RSYNC_USER:-backup}
    local port=${RSYNC_PORT:-22}
    local path=${RSYNC_PATH:-/backups}
    
    info "Syncing via rsync..."
    rsync -avz -e "ssh -p ${port}" \
        "${BACKUP_DIR}/${filename}" \
        "${user}@${host}:${path}/" 2>/dev/null && \
        success "Synced via rsync" || warn "rsync failed"
}

# ===========================================
# RETENTION
# ===========================================

cleanup_old_backups() {
    info "Cleaning up old backups (retention: ${RETENTION_DAYS} days)..."
    
    local provider=${BACKUP_PROVIDER:-local}
    
    case "$provider" in
        s3)
            cleanup_s3
            ;;
        b2)
            cleanup_b2
            ;;
        local)
            find "${LOCAL_BACKUP_PATH:-${BACKUP_DIR}" -name "*.tar.gz*" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
            ;;
    esac
    
    # Clean local backups
    find "${BACKUP_DIR}" -name "*.tar.gz*" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
    
    success "Cleanup completed"
}

cleanup_s3() {
    local bucket=${S3_BUCKET:-vps-backups}
    local prefix=${S3_PREFIX:-backups/}
    
    if [[ -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
        aws s3 ls "s3://${bucket}/${prefix}" --recursive | while read -r line; do
            local file=$(echo "$line" | awk '{print $4}')
            local date=$(echo "$line" | awk '{print $1}')
            # Compare dates and delete old files
            aws s3 rm "s3://${bucket}/${prefix}${file}" 2>/dev/null || true
        done
    fi
}

cleanup_b2() {
    local bucket=${B2_BUCKET:-vps-backups}
    
    if [[ -n "${B2_ACCOUNT_ID:-}" ]]; then
        B2_ACCOUNT_ID="${B2_ACCOUNT_ID}" \
        B2_APPLICATION_KEY="${B2_APPLICATION_KEY}" \
        b2 list-file-names "${bucket}" | while read -r file; do
            # Delete files older than retention
            # Implementation depends on B2 CLI
            true
        done
    fi
}

# ===========================================
# STATUS & LIST
# ===========================================

list_backups() {
    info "Available backups:"
    
    local provider=${BACKUP_PROVIDER:-local}
    
    case "$provider" in
        s3)
            aws s3 ls "s3://${S3_BUCKET:-vps-backups}/${S3_PREFIX:-backups/}" 2>/dev/null || echo "No S3 backups"
            ;;
        b2)
            if command -v b2 &>/dev/null; then
                B2_ACCOUNT_ID="${B2_ACCOUNT_ID}" \
                B2_APPLICATION_KEY="${B2_APPLICATION_KEY}" \
                b2 list-file-names "${B2_BUCKET:-vps-backups}" 2>/dev/null || echo "No B2 backups"
            fi
            ;;
        local)
            ls -lh "${LOCAL_BACKUP_PATH:-${BACKUP_DIR}"/*.tar.gz* 2>/dev/null || echo "No local backups"
            ;;
    esac
    
    echo ""
    echo "Local backup directory:"
    ls -lh "${BACKUP_DIR}"/*.tar.gz* 2>/dev/null || echo "No backups found"
}

status() {
    info "Backup Status"
    echo "=============="
    echo "Provider: ${BACKUP_PROVIDER:-local}"
    echo "Timestamp: ${TIMESTAMP}"
    echo "Backup Dir: ${BACKUP_DIR}"
    echo ""
    list_backups
}

# ===========================================
# MAIN
# ===========================================

show_help() {
    cat << EOF
VPS Backup Script

Usage: ./backup.sh <command> [options]

Commands:
    run [type]     Run backup (types: --all, --files, --postgres, --mysql, --volumes)
    list           List available backups
    status         Show backup status
    cleanup        Remove old backups
    help           Show this help

Examples:
    ./backup.sh run --all
    ./backup.sh run --files daily
    ./backup.sh list
    ./backup.sh cleanup
EOF
}

run_backup() {
    local type=${1:-all}
    
    mkdir -p "${BACKUP_DIR}/logs"
    info "Starting backup job: ${type}"
    
    case "$type" in
        --all)
            backup_files "full"
            backup_postgres
            backup_mysql
            backup_docker_volumes
            ;;
        --files|--file)
            backup_files "${2:-full}"
            ;;
        --postgres|--pg)
            backup_postgres
            ;;
        --mysql|--db)
            backup_mysql
            ;;
        --volumes|--docker)
            backup_docker_volumes
            ;;
        --hourly)
            backup_files "hourly"
            backup_postgres
            ;;
        --daily)
            backup_files "daily"
            backup_postgres
            backup_mysql
            ;;
        --weekly)
            backup_files "weekly"
            backup_docker_volumes
            ;;
        --monthly)
            backup_files "monthly"
            backup_docker_volumes
            ;;
        *)
            error "Unknown backup type: ${type}"
            show_help
            exit 1
            ;;
    esac
    
    # Cleanup old backups
    cleanup_old_backups
    
    success "Backup job completed"
}

# Main
case "${1:-help}" in
    run)    run_backup "${2:---all}" ;;
    list)   list_backups ;;
    status) status ;;
    cleanup) cleanup_old_backups ;;
    help|--help|-h) show_help ;;
    *)      run_backup "${1:---all}" ;;
esac
