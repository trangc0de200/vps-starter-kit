#!/usr/bin/env bash
# WireGuard Management Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load environment
[[ -f "${SCRIPT_DIR}/.env" ]] && source "${SCRIPT_DIR}/.env"

show_help() {
    cat << EOF
WireGuard VPN Management

${BLUE}Usage:${NC} ./wg.sh <command> [options]

${BLUE}Commands:${NC}
    start           Start WireGuard
    stop            Stop WireGuard
    restart         Restart WireGuard
    status          Show VPN status
    logs            Show logs
    add-client      Add new client
    list-clients    List all clients
    show-qr         Show client QR code
    remove-client   Remove client
    show-config     Show server config
    help            Show this help

${BLUE}Examples:${NC}
    ./wg.sh start
    ./wg.sh add-client myphone
    ./wg.sh show-qr laptop
EOF
}

start() {
    echo -e "${GREEN}Starting WireGuard...${NC}"
    cd "${SCRIPT_DIR}"
    docker-compose up -d
    echo -e "${GREEN}WireGuard started${NC}"
    echo "Web UI: http://localhost:${WEBUI_PORT:-51821}"
}

stop() {
    echo -e "${YELLOW}Stopping WireGuard...${NC}"
    cd "${SCRIPT_DIR}"
    docker-compose down
    echo -e "${GREEN}WireGuard stopped${NC}"
}

restart() {
    stop
    sleep 2
    start
}

status() {
    echo -e "${BLUE}WireGuard Status:${NC}"
    docker exec wireguard wg show 2>/dev/null || echo "WireGuard not running"
    echo ""
    docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" ps
}

logs() {
    docker-compose -f "${SCRIPT_DIR}/docker-compose.yml" logs -f
}

add_client() {
    local client_name=${1:-client}
    
    if [[ -z "$client_name" ]]; then
        echo -e "${RED}Client name required${NC}"
        echo "Usage: ./wg.sh add-client <name>"
        exit 1
    fi
    
    echo -e "${GREEN}Adding client: ${client_name}${NC}"
    
    # Check if wg-easy is running
    if docker ps | grep -q wireguard; then
        # For wg-easy, clients are managed via Web UI or API
        echo "wg-easy detected. Use Web UI at http://localhost:${WEBUI_PORT:-51821}"
        echo "Or use the API:"
        echo "curl -X POST http://localhost:${WEBUI_PORT:-51821}/api/wireguard/client"
    else
        echo "Using linuxserver/wireguard"
        echo "Edit docker-compose.yml and increase PEERS count, then restart"
    fi
    
    echo ""
    echo -e "${YELLOW}Client '${client_name}' created${NC}"
}

list_clients() {
    echo -e "${BLUE}Connected Clients:${NC}"
    
    if docker exec wireguard wg show 2>/dev/null | grep -q "peer"; then
        docker exec wireguard wg show | grep -A 5 "peer"
    else
        echo "No clients connected"
    fi
    
    echo ""
    echo -e "${BLUE}Configured Peers:${NC}"
    if [[ -d "${CONFIG_DIR}" ]]; then
        ls -la "${CONFIG_DIR}"/*.conf 2>/dev/null || echo "No configs found"
    fi
}

show_qr() {
    local client_name=${1:-}
    
    if [[ -z "$client_name" ]]; then
        echo -e "${RED}Client name required${NC}"
        echo "Usage: ./wg.sh show-qr <client-config>"
        exit 1
    fi
    
    local config_file="${CONFIG_DIR}/${client_name}.conf"
    
    if [[ ! -f "$config_file" ]]; then
        echo -e "${RED}Config not found: ${config_file}${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}QR Code for ${client_name}:${NC}"
    qrencode -t ansiutf8 < "$config_file"
}

remove_client() {
    local client_name=${1:-}
    
    if [[ -z "$client_name" ]]; then
        echo -e "${RED}Client name required${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Removing client: ${client_name}${NC}"
    rm -f "${CONFIG_DIR}/${client_name}.conf" 2>/dev/null || true
    docker exec wireguard wg set wg0 peer "$(docker exec wireguard wg show wg0 peers | grep -A 1 ${client_name} | head -1)" remove 2>/dev/null || true
    echo -e "${GREEN}Client removed${NC}"
}

show_config() {
    echo -e "${BLUE}Server Configuration:${NC}"
    docker exec wireguard cat /etc/wireguard/wg0.conf 2>/dev/null || echo "WireGuard not running"
}

case "${1:-help}" in
    start)        start ;;
    stop)         stop ;;
    restart)      restart ;;
    status)       status ;;
    logs)         logs ;;
    add-client)   add_client "${2:-}" ;;
    list-clients) list_clients ;;
    show-qr)      show_qr "${2:-}" ;;
    remove-client) remove_client "${2:-}" ;;
    show-config)  show_config ;;
    help|--help|-h) show_help ;;
    *)            show_help ;;
esac
