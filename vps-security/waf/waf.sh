#!/usr/bin/env bash
# WAF Management Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Actions
ACTION=${1:-help}

show_help() {
    cat << EOF
WAF Management Script

Usage: ./waf.sh <command>

Commands:
    start       Start WAF container
    stop        Stop WAF container
    restart     Restart WAF container
    logs        Show WAF logs
    status      Show WAF status
    stats       Show ModSecurity statistics
    reload      Reload Nginx configuration
    update      Update OWASP CRS rules
    test        Test configuration syntax
    enable      Enable WAF blocking mode
    disable     Disable WAF (DetectionOnly)
    ips         Show blocked/allowed IPs

Examples:
    ./waf.sh start
    ./waf.sh logs -f
    ./waf.sh enable
EOF
}

start_waf() {
    echo -e "${GREEN}Starting WAF...${NC}"
    docker-compose up -d
    echo -e "${GREEN}WAF started on ports 8080 (HTTP) and 8443 (HTTPS)${NC}"
}

stop_waf() {
    echo -e "${YELLOW}Stopping WAF...${NC}"
    docker-compose down
}

restart_waf() {
    echo -e "${YELLOW}Restarting WAF...${NC}"
    docker-compose restart
}

show_logs() {
    docker-compose logs -f --tail=100
}

show_status() {
    docker-compose ps
    echo ""
    echo "WAF Status:"
    docker exec waf nginx -v 2>&1 | head -1
}

show_stats() {
    echo "ModSecurity Status:"
    docker exec waf sh -c "curl -s http://localhost/modsec-status 2>/dev/null || echo 'Status endpoint not available'"
}

reload_nginx() {
    echo -e "${GREEN}Reloading Nginx configuration...${NC}"
    docker exec waf nginx -s reload
}

update_rules() {
    echo -e "${GREEN}Pulling latest OWASP CRS rules...${NC}"
    docker-compose pull
    docker-compose up -d
}

test_config() {
    echo -e "${GREEN}Testing Nginx configuration...${NC}"
    docker exec waf nginx -t
}

enable_blocking() {
    echo -e "${RED}Enabling WAF blocking mode...${NC}"
    docker-compose exec -T waf env MODSECURITY_MODE=On nginx -s reload
    echo -e "${GREEN}WAF blocking mode enabled${NC}"
}

disable_blocking() {
    echo -e "${YELLOW}Disabling WAF blocking mode (DetectionOnly)...${NC}"
    docker-compose exec -T waf env MODSECURITY_MODE=DetectionOnly nginx -s reload
    echo -e "${YELLOW}WAF in detection mode${NC}"
}

show_ips() {
    echo "Blocked IPs:"
    docker exec waf sh -c "cat /etc/modsecurity.d/custom/blacklist.txt 2>/dev/null || echo 'No blocked IPs'"
    echo ""
    echo "Allowed IPs:"
    docker exec waf sh -c "cat /etc/modsecurity.d/custom/whitelist.txt 2>/dev/null || echo 'No whitelisted IPs'"
}

# Execute command
case "${ACTION}" in
    start)      start_waf ;;
    stop)       stop_waf ;;
    restart)    restart_waf ;;
    logs)       show_logs ;;
    status)     show_status ;;
    stats)      show_stats ;;
    reload)     reload_nginx ;;
    update)     update_rules ;;
    test)       test_config ;;
    enable)     enable_blocking ;;
    disable)    disable_blocking ;;
    ips)        show_ips ;;
    help)       show_help ;;
    *)          show_help ;;
esac
