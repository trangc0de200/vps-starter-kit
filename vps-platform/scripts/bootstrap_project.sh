#!/usr/bin/env bash
# Bootstrap Project Script
# Initialize new project with standard structure

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    cat << EOF
${BLUE}VPS Platform - Project Bootstrap${NC}

Usage: $0 [OPTIONS]

Options:
    -n, --name NAME          Project name (required)
    -p, --path PATH         Installation path (default: /opt/{name})
    -s, --stack STACK        Stack type (docker|kubernetes|swarm)
    -m, --monitoring STACK  Monitoring (prometheus|none)
    -d, --domain DOMAIN     Domain name
    -h, --help             Show this help

Examples:
    $0 --name myapp --path /opt/myapp
    $0 -n api -s docker -m prometheus -d api.example.com
EOF
    exit 1
}

# Parse arguments
NAME=""
PATH=""
STACK="docker"
MONITORING="prometheus"
DOMAIN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--name) NAME="$2"; shift 2 ;;
        -p|--path) PATH="$2"; shift 2 ;;
        -s|--stack) STACK="$2"; shift 2 ;;
        -m|--monitoring) MONITORING="$2"; shift 2 ;;
        -d|--domain) DOMAIN="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Validate
if [[ -z "$NAME" ]]; then
    echo -e "${RED}Project name required${NC}"
    usage
fi

# Default path
if [[ -z "$PATH" ]]; then
    PATH="/opt/${NAME}"
fi

echo -e "${BLUE}Bootstrapping project: $NAME${NC}"
echo "Path: $PATH"
echo "Stack: $STACK"
echo "Monitoring: $MONITORING"

# Create directory structure
echo -e "\n${YELLOW}Creating directory structure...${NC}"
mkdir -p "${PATH}"/{src,config,logs,backup,health,nginx,prometheus}

# Create docker-compose.yml
echo -e "${YELLOW}Creating docker-compose.yml...${NC}"
cat > "${PATH}/docker-compose.yml" << 'EOF'
version: '3.8'

services:
  app:
    build: ./src
    container_name: APP_NAME
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
    volumes:
      - ./data:/data
    networks:
      - proxy_network
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    image: nginx:alpine
    container_name: APP_NAME-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx:/etc/nginx/conf.d:ro
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - app
    networks:
      - proxy_network

networks:
  proxy_network:
    name: proxy_network
    external: true

volumes:
  data:
    driver: local
EOF

# Update container names
sed -i "s/APP_NAME/${NAME}/g" "${PATH}/docker-compose.yml"

# Create .env
echo -e "${YELLOW}Creating .env...${NC}"
cat > "${PATH}/.env" << EOF
# Project
PROJECT_NAME=${NAME}
PROJECT_PATH=${PATH}

# Application
APP_PORT=3000
APP_ENV=production

# Domain
DOMAIN=${DOMAIN:-localhost}

# Backup
BACKUP_ENABLED=true
BACKUP_PATH=./backup
BACKUP_RETENTION=7

# Monitoring
MONITORING=${MONITORING}
EOF

# Create nginx config
echo -e "${YELLOW}Creating nginx config...${NC}"
cat > "${PATH}/nginx/default.conf" << EOF
server {
    listen 80;
    server_name ${DOMAIN:-localhost};

    location / {
        proxy_pass http://app:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /health {
        proxy_pass http://app:3000/health;
        access_log off;
    }

    location /metrics {
        proxy_pass http://app:3000/metrics;
        access_log off;
    }
}
EOF

# Create health check script
echo -e "${YELLOW}Creating health check script...${NC}"
cat > "${PATH}/health/health.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="${PROJECT_NAME:-app}"
ENDPOINT="${HEALTH_ENDPOINT:-http://localhost:3000/health}"

# Check endpoint
if curl -sf "$ENDPOINT" > /dev/null 2>&1; then
    echo "✓ $SERVICE_NAME is healthy"
    exit 0
else
    echo "✗ $SERVICE_NAME is unhealthy"
    exit 1
fi
EOF
chmod +x "${PATH}/health/health.sh"

# Create backup script
echo -e "${YELLOW}Creating backup script...${NC}"
cat > "${PATH}/backup/backup.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_DIR/backup}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup data
echo "Creating backup..."
tar -czf "$BACKUP_DIR/data_${TIMESTAMP}.tar.gz" -C "$PROJECT_DIR" data/ 2>/dev/null || true

# Backup config
tar -czf "$BACKUP_DIR/config_${TIMESTAMP}.tar.gz" -C "$PROJECT_DIR" config/ .env 2>/dev/null || true

# Cleanup old backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true

echo "Backup complete: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
EOF
chmod +x "${PATH}/backup/backup.sh"

# Create Prometheus config if monitoring enabled
if [[ "$MONITORING" == "prometheus" ]]; then
    echo -e "${YELLOW}Creating Prometheus config...${NC}"
    cat > "${PATH}/prometheus/prometheus.yml" << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: '${NAME}'
    static_configs:
      - targets: ['app:3000']
    metrics_path: /metrics
EOF
fi

# Create registry entry
echo -e "${YELLOW}Registering service...${NC}"
REGISTRY_FILE="${PLATFORM_DIR}/registry/services.json"
mkdir -p "${PLATFORM_DIR}/registry"

if [[ -f "$REGISTRY_FILE" ]]; then
    # Add to existing registry (using jq if available, else append)
    if command -v jq >/dev/null 2>&1; then
        jq --arg name "$NAME" \
           --arg path "$PATH" \
           --arg stack "$STACK" \
           --arg monitoring "$MONITORING" \
           --arg domain "${DOMAIN:-}" \
           --argjson timestamp "$(date -Iseconds)" \
           '.services += [{"name": $name, "path": $path, "stack": $stack, "monitoring": $monitoring, "domain": $domain, "status": "deployed", "created_at": $timestamp}]' \
           "$REGISTRY_FILE" > "${REGISTRY_FILE}.tmp" && mv "${REGISTRY_FILE}.tmp" "$REGISTRY_FILE"
    fi
else
    cat > "$REGISTRY_FILE" << EOF
{
  "services": [
    {
      "name": "${NAME}",
      "path": "${PATH}",
      "stack": "${STACK}",
      "monitoring": "${MONITORING}",
      "domain": "${DOMAIN:-}",
      "status": "deployed",
      "created_at": "$(date -Iseconds)"
    }
  ]
}
EOF
fi

# Create README
echo -e "${YELLOW}Creating README...${NC}"
cat > "${PATH}/README.md" << EOF
# ${NAME}

## Quick Start

\`\`\`bash
# Start services
docker-compose up -d

# Check health
./health/health.sh

# Backup
./backup/backup.sh

# View logs
docker-compose logs -f
\`\`\`

## Structure

- \`src/\` - Application code
- \`config/\` - Configuration files
- \`data/\` - Persistent data
- \`logs/\` - Log files
- \`nginx/\` - Nginx configuration
- \`backup/\` - Backup scripts

## Management

\`\`\`bash
# Restart
docker-compose restart

# Stop
docker-compose down

# Update
docker-compose pull && docker-compose up -d
\`\`\`
EOF

# Make scripts executable
chmod +x "${PATH}/health/health.sh" "${PATH}/backup/backup.sh"

echo -e "\n${GREEN}✓ Project bootstrapped successfully!${NC}"
echo ""
echo "Project location: $PATH"
echo "Registry: ${PLATFORM_DIR}/registry/services.json"
echo ""
echo "Next steps:"
echo "  1. cd $PATH"
echo "  2. Edit .env with your configuration"
echo "  3. Place your application in src/"
echo "  4. docker-compose up -d"
