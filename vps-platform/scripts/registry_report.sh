#!/usr/bin/env bash
# Registry Report Script
# Generate reports on deployed services

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
REGISTRY_FILE="${PLATFORM_DIR}/registry/services.json"

usage() {
    cat << EOF
${BLUE}VPS Platform - Registry Report${NC}

Usage: $0 [OPTIONS]

Options:
    -g, --generate         Generate/update report
    -l, --list            List all services
    -s, --service NAME    Filter by service
    -e, --export FORMAT   Export (json|csv|markdown)
    -o, --output FILE     Output file
    -h, --help           Show this help

Examples:
    $0 --generate          # Update registry with current status
    $0 --list              # List all services
    $0 --export csv        # Export as CSV
    $0 --service myapp     # Show specific service
EOF
    exit 1
}

# Parse arguments
GENERATE=false
LIST=false
SERVICE=""
EXPORT=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -g|--generate) GENERATE=true; shift ;;
        -l|--list) LIST=true; shift ;;
        -s|--service) SERVICE="$2"; shift 2 ;;
        -e|--export) EXPORT="$2"; shift 2 ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Ensure registry directory exists
mkdir -p "${PLATFORM_DIR}/registry"

# Check service health
check_health() {
    local name=$1
    local path=$2
    
    if [[ -f "${path}/health/health.sh" ]]; then
        if "${path}/health/health.sh" > /dev/null 2>&1; then
            echo "healthy"
        else
            echo "unhealthy"
        fi
    elif [[ -f "${path}/docker-compose.yml" ]]; then
        if docker ps --format '{{.Names}}' | grep -q "^${name}$"; then
            if docker ps --format '{{.Status}}' | grep -q "Up"; then
                echo "healthy"
            else
                echo "stopped"
            fi
        else
            echo "stopped"
        fi
    else
        echo "unknown"
    fi
}

# Generate report
generate_report() {
    echo -e "${BLUE}Generating registry report...${NC}"
    
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        echo -e "${YELLOW}Registry not found, creating new...${NC}"
        echo '{"services": []}' > "$REGISTRY_FILE"
    fi
    
    if command -v jq >/dev/null 2>&1; then
        # Update health status for each service
        local services_json=$(cat "$REGISTRY_FILE")
        local updated=false
        
        for entry in $(echo "$services_json" | jq -r '.services[] | @base64'); do
            local name=$(echo "$entry" | base64 -d | jq -r '.name')
            local path=$(echo "$entry" | base64 -d | jq -r '.path')
            
            if [[ -n "$path" && "$path" != "null" ]]; then
                local health=$(check_health "$name" "$path")
                services_json=$(echo "$services_json" | jq \
                    --arg name "$name" \
                    --arg health "$health" \
                    '.services |= map(if .name == $name then .health = $health else . end)')
                updated=true
            fi
        done
        
        if [[ "$updated" == "true" ]]; then
            echo "$services_json" > "$REGISTRY_FILE"
        fi
    fi
    
    echo -e "${GREEN}✓ Report generated${NC}"
}

# List services
list_services() {
    if [[ ! -f "$REGISTRY_FILE" ]]; then
        echo -e "${YELLOW}No registry found${NC}"
        return
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        cat "$REGISTRY_FILE"
        return
    fi
    
    # Filter by service if specified
    local filter=""
    if [[ -n "$SERVICE" ]]; then
        filter="| select(.name == \"$SERVICE\")"
    fi
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                         VPS Platform Registry                           ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║ Name          │ Status    │ Health     │ Path                        ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════════════╣${NC}"
    
    jq -r ".services[] $filter | \"║ \(.name // \"-\") | \(.status // \"-\") | \(.health // \"-\") | \(.path // \"-\")\"" \
        "$REGISTRY_FILE" 2>/dev/null | while read -r line; do
        printf "║%-15s║ %-9s║ %-10s║ %-30s║\n" \
            $(echo "$line" | awk -F'|' '{print $1, $2, $3, $4}')
    done
    
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════════════╝${NC}"
    
    local count=$(jq ".services | length" "$REGISTRY_FILE" 2>/dev/null || echo "0")
    echo ""
    echo "Total services: $count"
}

# Export functions
export_json() {
    if [[ -n "$OUTPUT" ]]; then
        jq '.' "$REGISTRY_FILE" > "$OUTPUT"
        echo "Exported to: $OUTPUT"
    else
        jq '.' "$REGISTRY_FILE"
    fi
}

export_csv() {
    if command -v jq >/dev/null 2>&1; then
        if [[ -n "$OUTPUT" ]]; then
            jq -r '.services[] | [.name, .path, .version, .status, .health, .domain] | @csv' "$REGISTRY_FILE" > "$OUTPUT"
            echo "name,path,version,status,health,domain" | cat - "$OUTPUT" > "${OUTPUT}.tmp" && mv "${OUTPUT}.tmp" "$OUTPUT"
            echo "Exported to: $OUTPUT"
        else
            echo "name,path,version,status,health,domain"
            jq -r '.services[] | [.name, .path, .version, .status, .health, .domain] | @csv' "$REGISTRY_FILE"
        fi
    fi
}

export_markdown() {
    if ! command -v jq >/dev/null 2>&1; then
        echo "jq required for markdown export"
        return
    fi
    
    local output=""
    
    output+="# VPS Platform Service Registry\n\n"
    output+="Generated: $(date)\n\n"
    output+="## Services\n\n"
    output+="| Name | Version | Status | Health | Domain | Path |\n"
    output+="|------|---------|--------|--------|--------|------|\n"
    
    jq -r '.services[] | "| \(.name) | \(.version // \"-\") | \(.status // \"-\") | \(.health // \"-\") | \(.domain // \"-\") | \(.path) |"' \
        "$REGISTRY_FILE" >> /dev/null 2>&1
    
    if [[ -n "$OUTPUT" ]]; then
        echo "$output" > "$OUTPUT"
        jq -r '.services[] | "| \(.name) | \(.version // \"-\") | \(.status // \"-\") | \(.health // \"-\") | \(.domain // \"-\") | \(.path) |"' "$REGISTRY_FILE" >> "$OUTPUT"
        echo "Exported to: $OUTPUT"
    else
        echo "$output"
        jq -r '.services[] | "| \(.name) | \(.version // \"-\") | \(.status // \"-\") | \(.health // \"-\") | \(.domain // \"-\") | \(.path) |"' "$REGISTRY_FILE"
    fi
}

# Main
if [[ "$GENERATE" == "true" ]]; then
    generate_report
elif [[ -n "$EXPORT" ]]; then
    case "$EXPORT" in
        json) export_json ;;
        csv) export_csv ;;
        markdown|md) export_markdown ;;
        *) echo "Unknown format: $EXPORT" ;;
    esac
elif [[ "$LIST" == "true" ]] || [[ -n "$SERVICE" ]]; then
    list_services
else
    usage
fi
