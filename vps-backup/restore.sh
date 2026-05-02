#!/usr/bin/env bash
# VPS Restore Script
# Restore backups from various sources

set -euo pipefail

# ===========================================
# CONFIGURATION
# ===========================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/.env" 2>/dev/null || true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Defaults
BACKUP_DIR="${SCRIPT_DIR}/backups"
LOG_FILE="${SCRIPT_DIR}/logs/restore_$(date +%Y%m%d_%H%M%S).log"

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

show_help() {
    cat << EOF
${CYAN}VPS Backup Restore Script${NC}

${BLUE}Usage:${NC} ./restore.sh <command> [options]

${BLUE}Commands:${NC}
    interactive           Interactive restore mode
    list                 List available backups
    postgres [options]   Restore PostgreSQL
    mysql [options]      Restore MySQL
    redis [options]      Restore Redis
    files [options]      Restore file backup
    volume [options]     Restore Docker volume

${BLUE}Options:${NC}
    --file <path>        Backup file to restore
    --database <name>    Target database name
    --target <path>      Target directory (for files)
    --volume <name>      Docker volume name
    --all                Restore all items
    --force              Skip confirmation
    --decrypt            Decrypt before restore
    --no-backup          Skip pre-restore backup

${BLUE}Examples:${NC}
    ./restore.sh interactive
    ./restore.sh list
    ./restore.sh postgres --file backups/postgres_20240115.sql.gz
    ./restore.sh mysql --file backups/mysql_20240115.sql.gz --database newdb
    ./restore.sh files --file backups/files_weekly.tar.gz --target /var/www
    ./restore.sh volume --file backups/volumes.tar.gz --volume mydata
EOF
    exit 1
}

# ===========================================
# LIST BACKUPS
# ===========================================

list_backups() {
    info "Available backups:"
    echo ""
    
    echo -e "${BLUE}PostgreSQL Backups:${NC}"
    if ls "${BACKUP_DIR}"/postgres_*.sql.gz 1>/dev/null 2>&1 || ls "${BACKUP_DIR}"/postgres_*.dump.gz 1>/dev/null 2>&1; then
        ls -lh "${BACKUP_DIR}"/postgres_*.sql.gz "${BACKUP_DIR}"/postgres_*.dump.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No PostgreSQL backups found"
    fi
    
    echo ""
    echo -e "${BLUE}MySQL Backups:${NC}"
    if ls "${BACKUP_DIR}"/mysql_*.sql.gz 1>/dev/null 2>&1; then
        ls -lh "${BACKUP_DIR}"/mysql_*.sql.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No MySQL backups found"
    fi
    
    echo ""
    echo -e "${BLUE}Redis Backups:${NC}"
    if ls "${BACKUP_DIR}"/redis_*.rdb.gz 1>/dev/null 2>&1; then
        ls -lh "${BACKUP_DIR}"/redis_*.rdb.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No Redis backups found"
    fi
    
    echo ""
    echo -e "${BLUE}File Backups:${NC}"
    if ls "${BACKUP_DIR}"/files_*.tar.gz 1>/dev/null 2>&1; then
        ls -lh "${BACKUP_DIR}"/files_*.tar.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No file backups found"
    fi
    
    echo ""
    echo -e "${BLUE}Volume Backups:${NC}"
    if ls "${BACKUP_DIR}"/volumes_*.tar.gz 1>/dev/null 2>&1; then
        ls -lh "${BACKUP_DIR}"/volumes_*.tar.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No volume backups found"
    fi
}

# ===========================================
# DECRYPT BACKUP
# ===========================================

decrypt_backup() {
    local encrypted_file=$1
    local password=${2:-$ENCRYPTION_PASSWORD}
    
    local output_file="${encrypted_file%.enc}"
    
    info "Decrypting backup..."
    openssl enc -aes-256-cbc -d -pbkdf2 \
        -in "$encrypted_file" \
        -out "$output_file" \
        -pass pass:"$password"
    
    success "Decrypted: $output_file"
    echo "$output_file"
}

# ===========================================
# RESTORE POSTGRESQL
# ===========================================

restore_postgres() {
    local backup_file=""
    local database="${POSTGRES_DB:-appdb}"
    local skip_confirm=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) backup_file="$2"; shift 2 ;;
            --database) database="$2"; shift 2 ;;
            --force) skip_confirm=true; shift ;;
            *) shift ;;
        esac
    done
    
    if [[ -z "$backup_file" ]]; then
        error "Backup file required. Use --file <path>"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    # Handle encrypted files
    if [[ "$backup_file" == *.enc ]]; then
        backup_file=$(decrypt_backup "$backup_file")
    fi
    
    # Warning
    if [[ "$skip_confirm" != "true" ]]; then
        warn "This will overwrite database: $database"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    info "Restoring PostgreSQL database: $database"
    
    # Create temp directory
    local temp_file="/tmp/restore_pg_$$.sql"
    
    # Decompress if needed
    if [[ "$backup_file" == *.gz ]]; then
        info "Decompressing..."
        gunzip -c "$backup_file" > "$temp_file"
    else
        cp "$backup_file" "$temp_file"
    fi
    
    # Check if custom format dump
    if [[ "$backup_file" == *.dump.gz ]] || [[ "$backup_file" == *.dump ]]; then
        info "Restoring from custom format..."
        docker exec -i postgres pg_restore -U postgres -d "$database" < "$temp_file" && \
            success "PostgreSQL restored successfully" || \
            error "Failed to restore PostgreSQL"
    else
        info "Restoring from SQL dump..."
        # Drop existing connections
        docker exec postgres psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$database';" 2>/dev/null || true
        docker exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS $database;"
        docker exec postgres psql -U postgres -c "CREATE DATABASE $database;"
        docker exec -i postgres psql -U postgres -d "$database" < "$temp_file" && \
            success "PostgreSQL restored successfully" || \
            error "Failed to restore PostgreSQL"
    fi
    
    # Cleanup
    rm -f "$temp_file"
}

# ===========================================
# RESTORE MYSQL
# ===========================================

restore_mysql() {
    local backup_file=""
    local database="${MYSQL_DB:-appdb}"
    local skip_confirm=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) backup_file="$2"; shift 2 ;;
            --database) database="$2"; shift 2 ;;
            --force) skip_confirm=true; shift ;;
            *) shift ;;
        esac
    done
    
    if [[ -z "$backup_file" ]]; then
        error "Backup file required. Use --file <path>"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    # Handle encrypted files
    if [[ "$backup_file" == *.enc ]]; then
        backup_file=$(decrypt_backup "$backup_file")
    fi
    
    # Warning
    if [[ "$skip_confirm" != "true" ]]; then
        warn "This will overwrite database: $database"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    info "Restoring MySQL database: $database"
    
    # Create temp file
    local temp_file="/tmp/restore_mysql_$$.sql"
    
    # Decompress if needed
    if [[ "$backup_file" == *.gz ]]; then
        info "Decompressing..."
        gunzip -c "$backup_file" > "$temp_file"
    else
        cp "$backup_file" "$temp_file"
    fi
    
    # Restore
    info "Restoring..."
    docker exec -i mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD:-changeme}" "$database" < "$temp_file" && \
        success "MySQL restored successfully" || \
        error "Failed to restore MySQL"
    
    # Cleanup
    rm -f "$temp_file"
}

# ===========================================
# RESTORE REDIS
# ===========================================

restore_redis() {
    local backup_file=""
    local volume=""
    local skip_confirm=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) backup_file="$2"; shift 2 ;;
            --volume) volume="$2"; shift 2 ;;
            --force) skip_confirm=true; shift ;;
            *) shift ;;
        esac
    done
    
    if [[ -z "$backup_file" ]]; then
        error "Backup file required. Use --file <path>"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    # Warning
    if [[ "$skip_confirm" != "true" ]]; then
        warn "This will overwrite Redis data!"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    info "Restoring Redis..."
    
    # Create temp file
    local temp_file="/tmp/restore_redis_$$.rdb"
    
    # Decompress if needed
    if [[ "$backup_file" == *.gz ]]; then
        gunzip -c "$backup_file" > "$temp_file"
    else
        cp "$backup_file" "$temp_file"
    fi
    
    # Stop Redis
    info "Stopping Redis..."
    docker exec redis redis-cli -a "${REDIS_PASSWORD:-}" SHUTDOWN SAVE 2>/dev/null || true
    sleep 2
    
    # Copy backup
    info "Copying backup..."
    docker cp "$temp_file" redis:/data/dump.rdb
    
    # Restart Redis
    info "Restarting Redis..."
    docker restart redis > /dev/null
    
    # Cleanup
    rm -f "$temp_file"
    
    success "Redis restored successfully"
}

# ===========================================
# RESTORE FILES
# ===========================================

restore_files() {
    local backup_file=""
    local target="/"
    local skip_confirm=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) backup_file="$2"; shift 2 ;;
            --target) target="$2"; shift 2 ;;
            --force) skip_confirm=true; shift ;;
            *) shift ;;
        esac
    done
    
    if [[ -z "$backup_file" ]]; then
        error "Backup file required. Use --file <path>"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    # Handle encrypted files
    if [[ "$backup_file" == *.enc ]]; then
        backup_file=$(decrypt_backup "$backup_file")
    fi
    
    # Warning
    if [[ "$skip_confirm" != "true" ]]; then
        warn "This will extract files to: $target"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    info "Restoring files to: $target"
    
    # Create target directory
    mkdir -p "$target"
    
    # Extract
    info "Extracting..."
    tar -xzf "$backup_file" -C "$target" --same-owner --preserve-permissions && \
        success "Files restored successfully" || \
        error "Failed to restore files"
}

# ===========================================
# RESTORE VOLUME
# ===========================================

restore_volume() {
    local backup_file=""
    local volume=""
    local skip_confirm=false
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) backup_file="$2"; shift 2 ;;
            --volume) volume="$2"; shift 2 ;;
            --force) skip_confirm=true; shift ;;
            *) shift ;;
        esac
    done
    
    if [[ -z "$backup_file" ]] || [[ -z "$volume" ]]; then
        error "Backup file and volume name required"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    # Warning
    if [[ "$skip_confirm" != "true" ]]; then
        warn "This will overwrite volume: $volume"
        read -p "Continue? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
    
    info "Restoring volume: $volume"
    
    # Create temp container
    info "Extracting..."
    docker run --rm \
        -v "${volume}:/data" \
        -v "${BACKUP_DIR}:/backup:ro" \
        alpine \
        sh -c "cd /data && tar -xzf /backup/$(basename "$backup_file")"
    
    success "Volume restored successfully"
}

# ===========================================
# INTERACTIVE MODE
# ===========================================

interactive() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Interactive Restore Mode${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    list_backups
    echo ""
    
    read -p "Select type to restore (postgres/mysql/redis/files/volume): " type
    
    case "$type" in
        postgres)
            read -p "Enter backup file path: " backup_file
            read -p "Enter database name [${POSTGRES_DB:-appdb}]: " database
            database=${database:-${POSTGRES_DB:-appdb}}
            restore_postgres --file "$backup_file" --database "$database"
            ;;
        mysql)
            read -p "Enter backup file path: " backup_file
            read -p "Enter database name [${MYSQL_DB:-appdb}]: " database
            database=${database:-${MYSQL_DB:-appdb}}
            restore_mysql --file "$backup_file" --database "$database"
            ;;
        redis)
            read -p "Enter backup file path: " backup_file
            restore_redis --file "$backup_file"
            ;;
        files)
            read -p "Enter backup file path: " backup_file
            read -p "Enter target directory [/]: " target
            target=${target:-/}
            restore_files --file "$backup_file" --target "$target"
            ;;
        volume)
            read -p "Enter backup file path: " backup_file
            read -p "Enter volume name: " volume
            restore_volume --file "$backup_file" --volume "$volume"
            ;;
        *)
            error "Invalid type: $type"
            ;;
    esac
}

# ===========================================
# MAIN
# ===========================================

# Create directories
mkdir -p "${BACKUP_DIR}" "${SCRIPT_DIR}/logs"

# Main
case "${1:-help}" in
    interactive) interactive ;;
    list) list_backups ;;
    postgres) shift; restore_postgres "$@" ;;
    mysql) shift; restore_mysql "$@" ;;
    redis) shift; restore_redis "$@" ;;
    files) shift; restore_files "$@" ;;
    volume) shift; restore_volume "$@" ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
