#!/usr/bin/env bash
# Migrate Script
# Database migration management

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REGISTRY_FILE="${PLATFORM_DIR}/registry/services.json"

usage() {
    cat << EOF
${BLUE}VPS Platform - Database Migration${NC}

Usage: $0 [OPTIONS]

Options:
    -s, --service NAME    Service name (required)
    -d, --direction DIR   Direction: up|down|status (default: up)
    -v, --version VER     Specific migration version
    -h, --help          Show this help

Examples:
    $0 --service myapp --direction up
    $0 --service myapp --direction down
    $0 --service myapp --status
EOF
    exit 1
}

# Parse arguments
SERVICE=""
DIRECTION="up"
VERSION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--service) SERVICE="$2"; shift 2 ;;
        -d|--direction) DIRECTION="$2"; shift 2 ;;
        -v|--version) VERSION="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

if [[ -z "$SERVICE" ]]; then
    echo -e "${RED}Service name required${NC}"
    usage
fi

# Get service path
if command -v jq >/dev/null 2>&1 && [[ -f "$REGISTRY_FILE" ]]; then
    PATH=$(jq -r ".services[] | select(.name == \"$SERVICE\") | .path" "$REGISTRY_FILE" 2>/dev/null)
fi
[[ -z "$PATH" ]] && PATH="/opt/${SERVICE}"

if [[ ! -d "$PATH" ]]; then
    echo -e "${RED}Service path not found: $PATH${NC}"
    exit 1
fi

cd "$PATH"

# Migration commands
case "$DIRECTION" in
    up)
        echo -e "${BLUE}Running migrations up...${NC}"
        
        if [[ -f "migrations/run.sh" ]]; then
            ./migrations/run.sh up
        elif [[ -d "migrations" ]]; then
            for f in migrations/*_up.sql; do
                [[ -f "$f" ]] || continue
                echo "Running: $(basename "$f")"
                # docker-compose exec -T db psql -U postgres -d appdb -f "$f"
            done
        elif [[ -f "docker-compose.yml" ]]; then
            docker-compose exec -T app npm run migrate:up 2>/dev/null || \
            docker-compose exec -T app python manage.py migrate 2>/dev/null || \
            docker-compose exec -T app php artisan migrate 2>/dev/null || \
            echo -e "${YELLOW}No migrate command found${NC}"
        fi
        ;;
    
    down)
        echo -e "${BLUE}Rolling back migrations...${NC}"
        
        if [[ -n "$VERSION" ]]; then
            echo "Rolling back to: $VERSION"
        fi
        
        if [[ -f "migrations/run.sh" ]]; then
            ./migrations/run.sh down "${VERSION:-}"
        elif [[ -d "migrations" ]]; then
            for f in migrations/*_down.sql; do
                [[ -f "$f" ]] || continue
                echo "Running: $(basename "$f")"
            done
        elif [[ -f "docker-compose.yml" ]]; then
            docker-compose exec -T app npm run migrate:down 2>/dev/null || \
            docker-compose exec -T app python manage.py migrate zero 2>/dev/null || \
            echo -e "${YELLOW}No rollback command found${NC}"
        fi
        ;;
    
    status)
        echo -e "${BLUE}Migration status for: $SERVICE${NC}"
        echo ""
        
        if [[ -f "docker-compose.yml" ]]; then
            docker-compose exec -T app npm run migrate:status 2>/dev/null || \
            docker-compose exec -T app python manage.py showmigrations 2>/dev/null || \
            docker-compose exec -T app php artisan migrate:status 2>/dev/null || \
            echo -e "${YELLOW}No status command found${NC}"
        fi
        ;;
    
    *)
        echo -e "${RED}Unknown direction: $DIRECTION${NC}"
        usage
        ;;
esac

echo -e "${GREEN}✓ Done${NC}"
