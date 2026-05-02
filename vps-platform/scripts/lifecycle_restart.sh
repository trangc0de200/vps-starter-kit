#!/usr/bin/env bash
# Lifecycle Restart Script
# Restart services with optional backup

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    cat << EOF
${BLUE}VPS Platform - Lifecycle Restart${NC}

Usage: $0 [OPTIONS]

Options:
    -s, --service NAME       Service name (required or --all)
    -a, --all               Restart all services
    -b, --backup            Backup before restart
    -f, --force             Force restart
    -t, --timeout SECONDS   Timeout (default: 60)
    -h, --help             Show this help

Examples:
    $0 --service nginx
    $0 --all --backup
    $0 --service myapp --force
EOF
    exit 1
}

# Parse arguments
SERVICE=""
ALL=false
BACKUP=false
FORCE=false
TIMEOUT=60

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--service) SERVICE="$2"; shift 2 ;;
        -a|--all) ALL=true; shift ;;
        -b|--backup) BACKUP=true; shift ;;
        -f|--force) FORCE=true; shift ;;
        -t|--timeout) TIMEOUT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Validate
if [[ -z "$SERVICE" ]] && [[ "$ALL" != "true" ]]; then
    echo -e "${RED}Service name or --all required${NC}"
    usage
fi

# Load registry
REGISTRY_FILE="${PLATFORM_DIR}/registry/services.json"

get_service_path() {
    local name=$1
    if [[ -f "$REGISTRY_FILE" ]] && command -v jq >/dev/null 2>&1; then
        jq -r ".services[] | select(.name == \"$name\") | .path" "$REGISTRY_FILE" 2>/dev/null
    fi
}

# Backup service
backup_service() {
    local name=$1
    local path=$2
    
    echo -e "${YELLOW}Backing up $name...${NC}"
    
    if [[ -f "${path}/backup/backup.sh" ]]; then
        cd "$path" && ./backup/backup.sh
    elif [[ -f "${path}/docker-compose.yml" ]]; then
        # Create backup
        mkdir -p "${path}/backup"
        local timestamp=$(date +%Y%m%d_%H%M%S)
        tar -czf "${path}/backup/${name}_${timestamp}.tar.gz" -C "$path" data/ config/ .env 2>/dev/null || true
        echo "Backup: ${path}/backup/${name}_${timestamp}.tar.gz"
    fi
}

# Restart service
restart_service() {
    local name=$1
    local path=$2
    
    echo -e "${BLUE}Restarting $name at $path...${NC}"
    
    if [[ ! -d "$path" ]]; then
        echo -e "${RED}Path not found: $path${NC}"
        return 1
    fi
    
    cd "$path"
    
    if [[ -f "docker-compose.yml" ]]; then
        # Health check before restart
        if [[ "$FORCE" != "true" ]]; then
            if ./health/health.sh 2>/dev/null; then
                echo "Service is healthy, proceeding with restart..."
            else
                echo -e "${YELLOW}Service is unhealthy, forcing restart...${NC}"
            fi
        fi
        
        # Restart
        docker-compose restart --timeout "$TIMEOUT"
        
        # Wait for health
        echo "Waiting for service to be healthy..."
        local count=0
        while [[ $count -lt 30 ]]; do
            if ./health/health.sh 2>/dev/null; then
                echo -e "${GREEN}✓ Service restarted successfully${NC}"
                return 0
            fi
            sleep 2
            ((count++))
        done
        
        echo -e "${RED}✗ Service did not become healthy${NC}"
        return 1
    else
        echo -e "${RED}docker-compose.yml not found${NC}"
        return 1
    fi
}

# Update registry
update_registry() {
    local name=$1
    local status=$2
    
    if [[ -f "$REGISTRY_FILE" ]] && command -v jq >/dev/null 2>&1; then
        jq --arg name "$name" \
           --arg status "$status" \
           --argjson timestamp "$(date -Iseconds)" \
           '.services |= map(if .name == $name then .status = $status | .last_restart = $timestamp else . end)' \
           "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
    fi
}

# Main
if [[ "$ALL" == "true" ]]; then
    echo -e "${BLUE}Restarting all services...${NC}"
    
    if [[ -f "$REGISTRY_FILE" ]] && command -v jq >/dev/null 2>&1; then
        services=$(jq -r '.services[].name' "$REGISTRY_FILE")
        for svc in $services; do
            path=$(get_service_path "$svc")
            if [[ -n "$path" && "$path" != "null" ]]; then
                if [[ "$BACKUP" == "true" ]]; then
                    backup_service "$svc" "$path" || true
                fi
                restart_service "$svc" "$path" && update_registry "$svc" "running"
            fi
        done
    else
        echo -e "${YELLOW}Registry not found, cannot restart all${NC}"
    fi
else
    path=$(get_service_path "$SERVICE")
    
    if [[ -z "$path" ]] || [[ "$path" == "null" ]]; then
        echo -e "${RED}Service not found in registry: $SERVICE${NC}"
        exit 1
    fi
    
    if [[ "$BACKUP" == "true" ]]; then
        backup_service "$SERVICE" "$path"
    fi
    
    if restart_service "$SERVICE" "$path"; then
        update_registry "$SERVICE" "running"
    else
        update_registry "$SERVICE" "unhealthy"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Restart complete${NC}"
