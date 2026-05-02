#!/usr/bin/env bash
# Lifecycle Redeploy Script
# Redeploy services with version control

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
${BLUE}VPS Platform - Lifecycle Redeploy${NC}

Usage: $0 [OPTIONS]

Options:
    -s, --service NAME       Service name (required or --all)
    -a, --all               Redeploy all services
    -v, --version VERSION   Specific version/tag
    -i, --image IMAGE       Docker image
    -r, --rollback          Rollback to previous version
    -b, --backup            Backup before redeploy
    -l, --list-versions     List available versions
    -h, --help             Show this help

Examples:
    $0 --service myapp --version v1.2.0
    $0 --service myapp --image myregistry/myapp:latest
    $0 --all --backup
    $0 --service myapp --rollback
EOF
    exit 1
}

# Parse arguments
SERVICE=""
ALL=false
VERSION=""
IMAGE=""
ROLLBACK=false
BACKUP=false
LIST_VERSIONS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--service) SERVICE="$2"; shift 2 ;;
        -a|--all) ALL=true; shift ;;
        -v|--version) VERSION="$2"; shift 2 ;;
        -i|--image) IMAGE="$2"; shift 2 ;;
        -r|--rollback) ROLLBACK=true; shift ;;
        -b|--backup) BACKUP=true; shift ;;
        -l|--list-versions) LIST_VERSIONS=true; shift ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Validate
if [[ -z "$SERVICE" ]] && [[ "$ALL" != "true" ]] && [[ "$LIST_VERSIONS" != "true" ]]; then
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

get_service_versions() {
    local name=$1
    local path=$2
    
    if [[ -d "${path}/.git" ]]; then
        git -C "$path" tag -l 2>/dev/null || echo "No tags"
    fi
    
    if command -v docker >/dev/null 2>&1; then
        echo "Docker images:"
        docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${name}\|^app/" 2>/dev/null || true
    fi
}

# Backup service
backup_service() {
    local name=$1
    local path=$2
    
    echo -e "${YELLOW}Backing up $name before redeploy...${NC}"
    
    mkdir -p "${path}/backup"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    if [[ -f "${path}/backup/backup.sh" ]]; then
        cd "$path" && ./backup/backup.sh
    fi
    
    # Backup entire directory
    tar -czf "${path}/backup/${name}_pre_redeploy_${timestamp}.tar.gz" \
        --exclude='./src/node_modules' \
        --exclude='./src/.git' \
        --exclude='./backup' \
        -C "$path" . 2>/dev/null || true
    
    echo "Backup saved: ${path}/backup/${name}_pre_redeploy_${timestamp}.tar.gz"
}

# Redeploy service
redeploy_service() {
    local name=$1
    local path=$2
    
    echo -e "${BLUE}Redeploying $name...${NC}"
    
    if [[ ! -d "$path" ]]; then
        echo -e "${RED}Path not found: $path${NC}"
        return 1
    fi
    
    cd "$path"
    
    # Backup if requested
    if [[ "$BACKUP" == "true" ]]; then
        backup_service "$name" "$path"
    fi
    
    # Rollback or deploy
    if [[ "$ROLLBACK" == "true" ]]; then
        echo "Rolling back $name..."
        
        if [[ -d "${path}/.git" ]]; then
            local prev_tag=$(git -C "$path" describe --tags --abbrev=0 HEAD^ 2>/dev/null)
            if [[ -n "$prev_tag" ]]; then
                git -C "$path" checkout "$prev_tag"
                echo "Rolled back to: $prev_tag"
            else
                echo -e "${RED}No previous version found${NC}"
                return 1
            fi
        fi
    elif [[ -n "$VERSION" ]]; then
        echo "Deploying version: $VERSION"
        
        if [[ -d "${path}/.git" ]]; then
            git -C "$path" checkout "$VERSION" 2>/dev/null || git -C "$path" checkout -b "$VERSION" 2>/dev/null
        fi
    elif [[ -n "$IMAGE" ]]; then
        echo "Using image: $IMAGE"
        sed -i "s|image: .*|image: ${IMAGE}|" docker-compose.yml 2>/dev/null || true
    fi
    
    # Pull latest code/images
    if [[ -f "docker-compose.yml" ]]; then
        docker-compose pull
        docker-compose up -d --build
        
        # Wait for health
        echo "Waiting for service to be healthy..."
        sleep 10
        
        if ./health/health.sh 2>/dev/null; then
            echo -e "${GREEN}✓ Redeployed successfully${NC}"
        else
            echo -e "${YELLOW}⚠ Service may need attention${NC}"
        fi
    else
        echo -e "${RED}docker-compose.yml not found${NC}"
        return 1
    fi
    
    # Update registry
    update_registry "$name" "running" "${VERSION:-$IMAGE}"
}

# Update registry
update_registry() {
    local name=$1
    local status=$2
    local version=$3
    
    if [[ -f "$REGISTRY_FILE" ]] && command -v jq >/dev/null 2>&1; then
        if [[ -n "$version" ]]; then
            jq --arg name "$name" \
               --arg status "$status" \
               --arg version "$version" \
               --argjson timestamp "$(date -Iseconds)" \
               '.services |= map(if .name == $name then .status = $status | .version = $version | .last_deploy = $timestamp else . end)' \
               "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
        else
            jq --arg name "$name" \
               --arg status "$status" \
               --argjson timestamp "$(date -Iseconds)" \
               '.services |= map(if .name == $name then .status = $status | .last_deploy = $timestamp else . end)' \
               "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
        fi
    fi
}

# List versions
list_versions() {
    local name=$1
    local path=$(get_service_path "$name")
    
    if [[ -z "$path" ]] || [[ "$path" == "null" ]]; then
        echo -e "${RED}Service not found: $name${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Versions for $name:${NC}"
    echo ""
    get_service_versions "$name" "$path"
}

# Main
if [[ "$LIST_VERSIONS" == "true" ]]; then
    list_versions "$SERVICE"
elif [[ "$ALL" == "true" ]]; then
    echo -e "${BLUE}Redeploying all services...${NC}"
    
    if [[ -f "$REGISTRY_FILE" ]] && command -v jq >/dev/null 2>&1; then
        services=$(jq -r '.services[].name' "$REGISTRY_FILE")
        for svc in $services; do
            path=$(get_service_path "$svc")
            if [[ -n "$path" && "$path" != "null" ]]; then
                redeploy_service "$svc" "$path"
            fi
        done
    else
        echo -e "${YELLOW}Registry not found${NC}"
    fi
else
    path=$(get_service_path "$SERVICE")
    
    if [[ -z "$path" ]] || [[ "$path" == "null" ]]; then
        echo -e "${RED}Service not found in registry: $SERVICE${NC}"
        exit 1
    fi
    
    redeploy_service "$SERVICE" "$path"
fi

echo -e "${GREEN}✓ Redeploy complete${NC}"
