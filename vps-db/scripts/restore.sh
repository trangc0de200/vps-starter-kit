#!/usr/bin/env bash
# Restore Database Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load environment
if [[ -f "${SCRIPT_DIR}/../.env" ]]; then
    source "${SCRIPT_DIR}/../.env"
fi

# Export passwords
export PGPASSWORD="${POSTGRES_PASSWORD:-change_me_strong_password}"
export MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-change_me_root_password}"

log() {
    local level=$1
    shift
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $*"
}

info() { log "${BLUE}INFO${NC}" "$*"; }
success() { log "${GREEN}SUCCESS${NC}" "$*"; }
warn() { log "${YELLOW}WARN${NC}" "$*"; }
error() { log "${RED}ERROR${NC}" "$*"; }

show_help() {
    cat << EOF
${CYAN}Database Restore Tool${NC}

${BLUE}Usage:${NC} ./restore.sh <command> [options]

${BLUE}Commands:${NC}
    list              List available backups
    postgres <file>   Restore PostgreSQL database
    mysql <file>     Restore MySQL database
    redis <file>     Restore Redis database
    interactive       Interactive restore mode

${BLUE}Options:${NC}
    --database <name>   Specify database name (for postgres/mysql)
    --target <path>     Target directory for backups

${BLUE}Examples:${NC}
    ./restore.sh list
    ./restore.sh postgres backups/postgres/postgres_20240101.sql.gz
    ./restore.sh postgres backup.dump --database myapp
    ./restore.sh interactive
EOF
}

list_backups() {
    info "Available backups:"
    echo ""
    
    echo -e "${BLUE}PostgreSQL Backups:${NC}"
    if ls backups/postgres/*.gz 1>/dev/null 2>&1; then
        ls -lh backups/postgres/*.gz | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No backups found"
    fi
    
    echo ""
    echo -e "${BLUE}MySQL Backups:${NC}"
    if ls backups/mysql/*.gz 1>/dev/null 2>&1; then
        ls -lh backups/mysql/*.gz | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No backups found"
    fi
    
    echo ""
    echo -e "${BLUE}Redis Backups:${NC}"
    if ls backups/redis/*.gz 1>/dev/null 2>&1; then
        ls -lh backups/redis/*.gz | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  No backups found"
    fi
}

restore_postgres() {
    local backup_file=$1
    local database=${2:-${POSTGRES_DB:-appdb}}
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    info "Restoring PostgreSQL database: ${database}"
    info "Backup file: ${backup_file}"
    
    # Check if container is running
    if ! docker ps | grep -q postgres; then
        error "PostgreSQL container is not running"
        exit 1
    fi
    
    # Stop application (optional warning)
    warn "Consider stopping your application before restore"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Restore cancelled"
        exit 0
    fi
    
    # Decompress if needed
    local temp_file="/tmp/restore_$$.sql"
    if [[ "$backup_file" == *.gz ]]; then
        info "Decompressing backup..."
        gunzip -c "$backup_file" > "$temp_file"
    else
        cp "$backup_file" "$temp_file"
    fi
    
    # Restore
    info "Restoring database..."
    
    # Check if it's a custom dump format
    if [[ "$backup_file" == *.dump.gz ]]; then
        docker exec -i postgres pg_restore -U postgres -d "${database}" < "$temp_file" && \
            success "PostgreSQL restored successfully" || \
            error "Failed to restore PostgreSQL"
    else
        # Drop and recreate database
        docker exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS ${database};" 2>/dev/null || true
        docker exec postgres psql -U postgres -c "CREATE DATABASE ${database};"
        docker exec -i postgres psql -U postgres -d "${database}" < "$temp_file" && \
            success "PostgreSQL restored successfully" || \
            error "Failed to restore PostgreSQL"
    fi
    
    # Cleanup
    rm -f "$temp_file"
}

restore_mysql() {
    local backup_file=$1
    local database=${2:-${MYSQL_DATABASE:-appdb}}
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    info "Restoring MySQL database: ${database}"
    info "Backup file: ${backup_file}"
    
    # Check if container is running
    if ! docker ps | grep -q mysql; then
        error "MySQL container is not running"
        exit 1
    fi
    
    # Warning
    warn "Consider stopping your application before restore"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Restore cancelled"
        exit 0
    fi
    
    # Decompress if needed
    local temp_file="/tmp/restore_$$.sql"
    if [[ "$backup_file" == *.gz ]]; then
        info "Decompressing backup..."
        gunzip -c "$backup_file" > "$temp_file"
    else
        cp "$backup_file" "$temp_file"
    fi
    
    # Restore
    info "Restoring database..."
    docker exec -i mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" "${database}" < "$temp_file" && \
        success "MySQL restored successfully" || \
        error "Failed to restore MySQL"
    
    # Cleanup
    rm -f "$temp_file"
}

restore_redis() {
    local backup_file=$1
    
    if [[ ! -f "$backup_file" ]]; then
        error "Backup file not found: $backup_file"
        exit 1
    fi
    
    info "Restoring Redis..."
    info "Backup file: ${backup_file}"
    
    # Check if container is running
    if ! docker ps | grep -q redis; then
        error "Redis container is not running"
        exit 1
    fi
    
    # Warning
    warn "This will replace all existing Redis data"
    read -p "Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Restore cancelled"
        exit 0
    fi
    
    # Decompress if needed
    local temp_file="/tmp/restore_$$.rdb"
    if [[ "$backup_file" == *.gz ]]; then
        info "Decompressing backup..."
        gunzip -c "$backup_file" > "$temp_file"
    else
        cp "$backup_file" "$temp_file"
    fi
    
    # Stop Redis
    info "Stopping Redis..."
    docker exec redis redis-cli -a "${REDIS_PASSWORD:-}" SHUTDOWN SAVE 2>/dev/null || true
    sleep 2
    
    # Copy backup
    info "Copying backup file..."
    docker cp "$temp_file" redis:/data/dump.rdb
    
    # Restart Redis
    info "Restarting Redis..."
    docker restart redis 2>/dev/null || docker-compose restart redis
    
    # Cleanup
    rm -f "$temp_file"
    
    success "Redis restored successfully"
}

interactive() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Interactive Restore Mode${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    list_backups
    echo ""
    
    read -p "Select database type (postgres/mysql/redis): " db_type
    
    case "$db_type" in
        postgres)
            read -p "Enter backup file path: " backup_file
            read -p "Enter database name [${POSTGRES_DB:-appdb}]: " database
            database=${database:-${POSTGRES_DB:-appdb}}
            restore_postgres "$backup_file" "$database"
            ;;
        mysql)
            read -p "Enter backup file path: " backup_file
            read -p "Enter database name [${MYSQL_DATABASE:-appdb}]: " database
            database=${database:-${MYSQL_DATABASE:-appdb}}
            restore_mysql "$backup_file" "$database"
            ;;
        redis)
            read -p "Enter backup file path: " backup_file
            restore_redis "$backup_file"
            ;;
        *)
            error "Invalid database type: $db_type"
            ;;
    esac
}

# Main
case "${1:-help}" in
    list) list_backups ;;
    postgres) restore_postgres "${2:-}" "${3:-}" ;;
    mysql) restore_mysql "${2:-}" "${3:-}" ;;
    redis) restore_redis "${2:-}" ;;
    interactive) interactive ;;
    help|--help|-h) show_help ;;
    *) show_help ;;
esac
