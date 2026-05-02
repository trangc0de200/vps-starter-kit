#!/usr/bin/env bash
# Rollback Script
# Rollback to previous version

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-${APP_DIR}/backups}"

usage() {
    cat << EOF
${BLUE}Rollback Script${NC}

Usage: $0 [OPTIONS]

Options:
    --version VERSION    Specific version to rollback to
    --list              List available versions
    -v, --verbose      Verbose output
    -h, --help         Show this help

Examples:
    $0                  # Rollback to previous
    $0 --list           # List versions
    $0 --version v1.0.0  # Rollback to specific version
EOF
    exit 1
}

# Parse arguments
VERSION=""
LIST=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --list) LIST=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# List versions
list_versions() {
    echo -e "${BLUE}Available versions:${NC}"
    echo ""
    
    if [[ -d "$BACKUP_DIR" ]]; then
        ls -lt "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -20 | while read -r line; do
            echo "$line"
        done
    else
        echo "No backups found in $BACKUP_DIR"
    fi
}

# Get latest backup
get_latest_backup() {
    ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | head -1
}

# Rollback
rollback() {
    local backup_file=$1
    
    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}Backup not found: $backup_file${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Rolling back to: $(basename "$backup_file")${NC}"
    
    # Stop current
    if [[ -f "${APP_DIR}/docker-compose.yml" ]]; then
        cd "$APP_DIR"
        docker-compose stop app 2>/dev/null || true
    fi
    
    # Extract backup
    echo "Extracting backup..."
    cd "$APP_DIR"
    
    # Create current backup first
    if [[ -d "${APP_DIR}/data" ]]; then
        mkdir -p "${BACKUP_DIR}"
        tar -czf "${BACKUP_DIR}/pre-rollback-$(date +%Y%m%d_%H%M%S).tar.gz" data/ 2>/dev/null || true
    fi
    
    # Extract
    tar -xzf "$backup_file" -C /tmp/ 2>/dev/null || true
    
    # Restore files
    if [[ -d "/tmp/data" ]]; then
        rm -rf "${APP_DIR}/data"
        mv /tmp/data "${APP_DIR}/data"
    fi
    
    # Restart
    if [[ -f "${APP_DIR}/docker-compose.yml" ]]; then
        docker-compose up -d app
    fi
    
    echo -e "${GREEN}Rollback complete${NC}"
}

# Main
if [[ "$LIST" == "true" ]]; then
    list_versions
else
    if [[ -z "$VERSION" ]]; then
        # Use latest backup
        backup=$(get_latest_backup)
        if [[ -z "$backup" ]]; then
            echo -e "${RED}No backups found${NC}"
            exit 1
        fi
        rollback "$backup"
    else
        # Find specific version
        backup="${BACKUP_DIR}/app-${VERSION}.tar.gz"
        if [[ ! -f "$backup" ]]; then
            # Try glob
            backup=$(ls "$BACKUP_DIR"/*"${VERSION}"*.tar.gz 2>/dev/null | head -1)
        fi
        rollback "$backup"
    fi
fi
