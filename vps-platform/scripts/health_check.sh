#!/usr/bin/env bash
# Health Check Script
# Check health of deployed services

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
${BLUE}VPS Platform - Health Check${NC}

Usage: $0 [OPTIONS]

Options:
    -s, --service NAME    Check specific service
    -a, --all            Check all services (default)
    -w, --watch          Continuous monitoring
    -i, --interval SECS  Check interval (default: 30)
    -j, --json           JSON output
    -h, --help          Show this help

Examples:
    $0 --all             # Check all services
    $0 --service myapp   # Check specific service
    $0 --watch --interval 60  # Continuous monitoring
EOF
    exit 1
}

# Parse arguments
SERVICE=""
ALL=false
WATCH=false
INTERVAL=30
JSON=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--service) SERVICE="$2"; shift 2 ;;
        -a|--all) ALL=true; shift ;;
        -w|--watch) WATCH=true; shift ;;
        -i|--interval) INTERVAL="$2"; shift 2 ;;
        -j|--json) JSON=true; shift ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

if [[ -z "$SERVICE" ]] && [[ "$ALL" != "true" ]]; then
    ALL=true
fi

# Check single service
check_service() {
    local name=$1
    local path=$2
    
    local status="unknown"
    local health="unknown"
    local uptime="N/A"
    
    # Check if path exists
    if [[ ! -d "$path" ]]; then
        status="not_found"
        echo "$name:$status:$health:$uptime"
        return
    fi
    
    # Check Docker container
    if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
        status="running"
        local docker_status=$(docker ps --filter "name=^${name}$" --format '{{.Status}}')
        
        # Extract uptime from status
        uptime=$(echo "$docker_status" | grep -oP '\d+ (minutes|hours|days)' || echo "unknown")
        
        # Check health endpoint if exists
        if [[ -f "${path}/health/health.sh" ]]; then
            if "${path}/health/health.sh" > /dev/null 2>&1; then
                health="healthy"
            else
                health="unhealthy"
                status="degraded"
            fi
        else
            health="unknown"
        fi
    else
        status="stopped"
        health="n/a"
    fi
    
    echo "$name:$status:$health:$uptime"
}

# Run checks
run_checks() {
    if [[ "$JSON" == "true" ]]; then
        echo "{"
        echo "  \"timestamp\": \"$(date -Iseconds)\","
        echo "  \"services\": ["
    else
        echo -e "${BLUE}========================================${NC}"
        echo -e "${BLUE}  VPS Platform Health Check${NC}"
        echo -e "${BLUE}  $(date)${NC}"
        echo -e "${BLUE}========================================${NC}"
        echo ""
        printf "%-15s %-12s %-10s %s\n" "SERVICE" "STATUS" "HEALTH" "UPTIME"
        echo "────────────────────────────────────────────────"
    fi
    
    local first=true
    
    if [[ -n "$SERVICE" ]]; then
        # Single service
        if command -v jq >/dev/null 2>&1 && [[ -f "$REGISTRY_FILE" ]]; then
            path=$(jq -r ".services[] | select(.name == \"$SERVICE\") | .path" "$REGISTRY_FILE" 2>/dev/null)
        fi
        [[ -z "$path" ]] && path="/opt/${SERVICE}"
        
        result=$(check_service "$SERVICE" "$path")
        
        IFS=':' read -r name status health uptime <<< "$result"
        
        if [[ "$JSON" == "true" ]]; then
            echo "    {\"name\": \"$name\", \"status\": \"$status\", \"health\": \"$health\", \"uptime\": \"$uptime\"}"
            echo "  ]"
            echo "}"
        else
            local color=$GREEN
            [[ "$status" != "running" ]] && color=$RED
            [[ "$status" == "degraded" ]] && color=$YELLOW
            
            printf "%-15s ${color}%-12s${NC} %-10s %s\n" "$name" "$status" "$health" "$uptime"
        fi
    else
        # All services
        if command -v jq >/dev/null 2>&1 && [[ -f "$REGISTRY_FILE" ]]; then
            services=$(jq -r '.services[].name' "$REGISTRY_FILE" 2>/dev/null)
            
            for svc in $services; do
                path=$(jq -r ".services[] | select(.name == \"$svc\") | .path" "$REGISTRY_FILE" 2>/dev/null)
                result=$(check_service "$svc" "$path")
                
                IFS=':' read -r name status health uptime <<< "$result"
                
                if [[ "$JSON" == "true" ]]; then
                    [[ "$first" == "false" ]] && echo ","
                    echo -n "    {\"name\": \"$name\", \"status\": \"$status\", \"health\": \"$health\", \"uptime\": \"$uptime\"}"
                    first=false
                else
                    local color=$GREEN
                    [[ "$status" != "running" ]] && color=$RED
                    [[ "$status" == "degraded" ]] && color=$YELLOW
                    
                    printf "%-15s ${color}%-12s${NC} %-10s %s\n" "$name" "$status" "$health" "$uptime"
                fi
            done
        fi
        
        if [[ "$JSON" == "true" ]]; then
            echo ""
            echo "  ]"
            echo "}"
        fi
    fi
}

# Watch mode
if [[ "$WATCH" == "true" ]]; then
    echo -e "${BLUE}Starting continuous monitoring (Ctrl+C to stop)${NC}"
    echo ""
    
    while true; do
        clear
        run_checks
        echo ""
        echo -e "${YELLOW}Next check in ${INTERVAL}s...${NC}"
        sleep "$INTERVAL"
    done
else
    run_checks
fi
