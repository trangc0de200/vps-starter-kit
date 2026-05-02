#!/usr/bin/env bash
# Health Check Script
# Check if application is healthy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configuration
HOST="${HEALTH_HOST:-localhost}"
PORT="${APP_PORT:-3000}"
ENDPOINT="${HEALTH_ENDPOINT:-http://${HOST}:${PORT}/health}"
TIMEOUT="${HEALTH_TIMEOUT:-5}"

# Check if container is running
check_container() {
    local container_name="${CONTAINER_NAME:-app}"
    
    if docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        return 0
    else
        return 1
    fi
}

# HTTP health check
check_http() {
    local response
    local http_code
    
    response=$(curl -sf -m "$TIMEOUT" "$ENDPOINT" 2>/dev/null) || return 1
    http_code=$(curl -sf -o /dev/null -w "%{http_code}" -m "$TIMEOUT" "$ENDPOINT" 2>/dev/null) || return 1
    
    # Accept 200 or 204
    if [[ "$http_code" =~ ^(200|204)$ ]]; then
        echo "$response"
        return 0
    fi
    
    return 1
}

# TCP port check
check_port() {
    if command -v nc >/dev/null 2>&1; then
        nc -z -w "$TIMEOUT" "$HOST" "$PORT"
    elif command -v timeout >/dev/null 2>&1; then
        timeout "$TIMEOUT" bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT" 2>/dev/null
    else
        # Fallback to curl
        curl -sf -m "$TIMEOUT" "http://${HOST}:${PORT}/" > /dev/null 2>&1
    fi
}

# Main check
main() {
    # Check if container is running
    if ! check_container; then
        echo "Container not running"
        exit 1
    fi
    
    # Try HTTP check first
    if check_http; then
        echo "Healthy"
        exit 0
    fi
    
    # Fallback to port check
    if check_port; then
        echo "Port open (HTTP check unavailable)"
        exit 0
    fi
    
    echo "Unhealthy"
    exit 1
}

main
