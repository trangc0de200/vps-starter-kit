#!/usr/bin/env bash
# Deploy Script
# Deploy application to staging or production

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    cat << EOF
${BLUE}Application Deploy Script${NC}

Usage: $0 [OPTIONS]

Options:
    -e, --env ENV         Environment (staging|production) [required]
    -b, --branch BRANCH  Git branch (default: main)
    --backup             Backup before deploy
    --migrate            Run migrations after deploy
    --no-health          Skip health check
    -v, --verbose        Verbose output
    -h, --help          Show this help

Examples:
    $0 --env production
    $0 --env staging --backup --migrate
    $0 --env production --branch develop
EOF
    exit 1
}

# Parse arguments
ENV=""
BRANCH="main"
BACKUP=false
MIGRATE=false
NO_HEALTH=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--env) ENV="$2"; shift 2 ;;
        -b|--branch) BRANCH="$2"; shift 2 ;;
        --backup) BACKUP=true; shift ;;
        --migrate) MIGRATE=true; shift ;;
        --no-health) NO_HEALTH=true; shift ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Validate
if [[ -z "$ENV" ]]; then
    echo -e "${RED}Environment required (staging|production)${NC}"
    usage
fi

if [[ ! "$ENV" =~ ^(staging|production)$ ]]; then
    echo -e "${RED}Invalid environment: $ENV${NC}"
    usage
fi

# Load environment
ENV_FILE="${APP_DIR}/.env.${ENV}"
if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo -e "${YELLOW}Warning: $ENV_FILE not found${NC}"
fi

# Logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✓ $*"
}

log_warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠ $*"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✗ $*"
}

# Backup
do_backup() {
    if [[ "$BACKUP" == "true" ]] && [[ -f "${SCRIPT_DIR}/backup.sh" ]]; then
        log "Creating backup..."
        "${SCRIPT_DIR}/backup.sh" || log_warn "Backup failed, continuing..."
    fi
}

# Health check
health_check() {
    if [[ "$NO_HEALTH" == "true" ]]; then
        return 0
    fi
    
    log "Running health check..."
    if "${SCRIPT_DIR}/healthcheck.sh"; then
        log_success "Health check passed"
        return 0
    else
        log_error "Health check failed"
        return 1
    fi
}

# Pre-deployment
pre_deploy() {
    log "Pre-deployment checks..."
    
    # Check docker-compose
    if [[ ! -f "${APP_DIR}/docker-compose.yml" ]]; then
        cp "${APP_DIR}/docker-compose.yml.example" "${APP_DIR}/docker-compose.yml" 2>/dev/null || true
    fi
    
    log_success "Pre-deployment complete"
}

# Git pull
git_pull() {
    if [[ -d "${APP_DIR}/.git" ]]; then
        log "Pulling latest code from $BRANCH..."
        git -C "$APP_DIR" pull origin "$BRANCH"
    fi
}

# Build
build() {
    log "Building application..."
    cd "$APP_DIR"
    
    if [[ -f "docker-compose.yml" ]]; then
        docker-compose build --no-cache app
    else
        docker build -t "${IMAGE_NAME:-app}:${ENV}" .
    fi
    
    log_success "Build complete"
}

# Migrate
do_migrate() {
    if [[ "$MIGRATE" == "true" ]] && [[ -f "${SCRIPT_DIR}/migrate.sh" ]]; then
        log "Running migrations..."
        "${SCRIPT_DIR}/migrate.sh" up || log_warn "Migration had issues"
    fi
}

# Deploy
deploy() {
    log "Deploying to $ENV..."
    cd "$APP_DIR"
    
    # Pull latest image
    if [[ -f "docker-compose.yml" ]]; then
        docker-compose pull app
        docker-compose up -d app
    else
        docker stop "${IMAGE_NAME:-app}" 2>/dev/null || true
        docker run -d --name "${IMAGE_NAME:-app}" \
            --restart unless-stopped \
            -p "${APP_PORT:-3000}:3000" \
            "${IMAGE_NAME:-app}:${ENV}"
    fi
    
    log_success "Deployed"
}

# Post-deployment
post_deploy() {
    log "Post-deployment checks..."
    
    # Wait for startup
    sleep 5
    
    # Health check
    health_check || log_warn "Post-deployment health check failed"
    
    # Cleanup
    docker system prune -f > /dev/null 2>&1 || true
    
    log_success "Deployment complete"
}

# Rollback on failure
rollback() {
    log_error "Deployment failed, rolling back..."
    
    if [[ "$BACKUP" == "true" ]] && [[ -f "${SCRIPT_DIR}/rollback.sh" ]]; then
        "${SCRIPT_DIR}/rollback.sh" || log_warn "Rollback failed"
    fi
    
    exit 1
}

# Main
main() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}  Deploying to ${ENV}${NC}"
    echo -e "${CYAN}========================================${NC}"
    
    trap 'rollback' ERR
    
    pre_deploy
    do_backup
    git_pull
    build
    do_migrate
    deploy
    post_deploy
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  Deploy Complete${NC}"
    echo -e "${GREEN}========================================${NC}"
}

main
