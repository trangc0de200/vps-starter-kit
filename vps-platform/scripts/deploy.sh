#!/usr/bin/env bash
# Deploy Script
# Deploy services from git or docker image

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
${BLUE}VPS Platform - Deploy${NC}

Usage: $0 [OPTIONS]

Options:
    -n, --name NAME           Service name (required)
    -g, --git URL            Git repository
    -b, --branch BRANCH      Git branch (default: main)
    -i, --image IMAGE        Docker image
    -v, --version VERSION    Specific version
    -p, --path PATH          Installation path
    -m, --monitoring         Enable monitoring
    -d, --domain DOMAIN     Domain name
    -b, --backup             Backup before deploy
    --dry-run                Show what would be done
    -v, --verbose            Verbose output
    -h, --help             Show this help

Examples:
    $0 --name myapp --git https://github.com/user/myapp.git
    $0 --name myapp --image myregistry/myapp:latest
    $0 --name myapp --version v1.2.0
EOF
    exit 1
}

# Parse arguments
NAME=""
GIT=""
BRANCH="main"
IMAGE=""
VERSION=""
PATH=""
MONITORING=false
DOMAIN=""
BACKUP=false
DRY_RUN=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name) NAME="$2"; shift 2 ;;
        -g|--git) GIT="$2"; shift 2 ;;
        -b|--branch) BRANCH="$2"; shift 2 ;;
        -i|--image) IMAGE="$2"; shift 2 ;;
        -v|--version) VERSION="$2"; shift 2 ;;
        -p|--path) PATH="$2"; shift 2 ;;
        -m|--monitoring) MONITORING=true; shift ;;
        -d|--domain) DOMAIN="$2"; shift 2 ;;
        --backup) BACKUP=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        --verbose) VERBOSE=true; shift ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Validate
if [[ -z "$NAME" ]]; then
    echo -e "${RED}Service name required${NC}"
    usage
fi

if [[ -z "$GIT" ]] && [[ -z "$IMAGE" ]]; then
    echo -e "${RED}Git repository or Docker image required${NC}"
    usage
fi

# Default path
if [[ -z "$PATH" ]]; then
    PATH="/opt/${NAME}"
fi

# Verbose output
log() {
    [[ "$VERBOSE" == "true" ]] && echo -e "${BLUE}[DEBUG]${NC} $*"
}

echo -e "${BLUE}Deploying: $NAME${NC}"
echo "Path: $PATH"

# Pre-deploy checks
echo -e "\n${YELLOW}Running pre-deploy checks...${NC}"

if [[ -d "$PATH" ]]; then
    echo -e "${YELLOW}Warning: Path already exists: $PATH${NC}"
    if [[ "$DRY_RUN" != "true" ]]; then
        read -p "Continue? (y/N) " -n 1 -r
        echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && exit 0
    fi
fi

# Dry run
if [[ "$DRY_RUN" == "true" ]]; then
    echo -e "\n${CYAN}[DRY RUN] Would do the following:${NC}"
    [[ -n "$GIT" ]] && echo "  - Clone git: $GIT (branch: $BRANCH)"
    [[ -n "$IMAGE" ]] && echo "  - Pull image: $IMAGE"
    echo "  - Create service at: $PATH"
    [[ "$MONITORING" == "true" ]] && echo "  - Enable monitoring"
    [[ "$BACKUP" == "true" ]] && echo "  - Create backup"
    exit 0
fi

# Create directory
mkdir -p "$PATH"

# Clone or pull git
if [[ -n "$GIT" ]]; then
    echo -e "${YELLOW}Cloning repository...${NC}"
    
    if [[ -d "${PATH}/.git" ]]; then
        log "Git directory exists, pulling..."
        git -C "$PATH" pull
    else
        git clone --branch "$BRANCH" "$GIT" "$PATH"
    fi
    
    # Checkout specific version if provided
    if [[ -n "$VERSION" ]]; then
        log "Checking out version: $VERSION"
        git -C "$PATH" checkout "$VERSION"
    fi
fi

# Pull image if provided
if [[ -n "$IMAGE" ]]; then
    echo -e "${YELLOW}Pulling Docker image...${NC}"
    docker pull "$IMAGE"
    
    # Update docker-compose.yml to use image
    if [[ -f "${PATH}/docker-compose.yml" ]]; then
        sed -i "s|image: .*|image: ${IMAGE}|" "${PATH}/docker-compose.yml"
    fi
fi

# Create standard structure if not exists
mkdir -p "${PATH}"/{config,logs,backup,health,nginx,prometheus}

# Enable monitoring
if [[ "$MONITORING" == "true" ]]; then
    log "Enabling monitoring..."
    
    # Add Prometheus config
    cat > "${PATH}/prometheus/prometheus.yml" << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: '${NAME}'
    static_configs:
      - targets: ['app:3000']
EOF
fi

# Register service
echo -e "${YELLOW}Registering service...${NC}"
REGISTRY_FILE="${PLATFORM_DIR}/registry/services.json"
mkdir -p "${PLATFORM_DIR}/registry"

# Add to registry
if command -v jq >/dev/null 2>&1; then
    local service_json=$(jq -n \
        --arg name "$NAME" \
        --arg path "$PATH" \
        --arg git "$GIT" \
        --arg branch "$BRANCH" \
        --arg version "${VERSION:-$IMAGE}" \
        --arg domain "$DOMAIN" \
        --arg monitoring "$MONITORING" \
        --argjson timestamp "$(date -Iseconds)" \
        '{
            name: $name,
            path: $path,
            git: $git,
            branch: $branch,
            version: $version,
            domain: $domain,
            monitoring: $monitoring,
            status: "deployed",
            created_at: $timestamp
        }')
    
    if [[ -f "$REGISTRY_FILE" ]]; then
        jq ".services += [$service_json]" "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && \
            mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
    else
        jq -n "{\"services\": [$service_json]}" > "$REGISTRY_FILE"
    fi
fi

# Start service
if [[ -f "${PATH}/docker-compose.yml" ]]; then
    echo -e "${YELLOW}Starting service...${NC}"
    cd "$PATH" && docker-compose up -d
fi

echo -e "\n${GREEN}✓ Deployed successfully!${NC}"
echo ""
echo "Service: $NAME"
echo "Path: $PATH"
echo "Registry: $REGISTRY_FILE"
