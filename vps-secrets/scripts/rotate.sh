#!/usr/bin/env bash
# Secret Rotation Script
# Rotate secrets with backup and notification

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/../backups"
SECRETS_DIR="${SCRIPT_DIR}/../secrets"

usage() {
    cat << EOF
${BLUE}VPS Secret Rotation${NC}

Usage: $0 [OPTIONS]

Options:
    -s, --secret NAME       Secret name to rotate
    -a, --all              Rotate all secrets
    -k, --keep N           Number of old secrets to keep (default: 5)
    -n, --notify           Send notification after rotation
    -h, --help            Show this help

Examples:
    $0 -s db_password           # Rotate single secret
    $0 -a                       # Rotate all secrets
    $0 -a -k 10                 # Rotate all, keep 10 old
EOF
    exit 1
}

# Load config
load_config() {
    if [[ -f "${SCRIPT_DIR}/.config" ]]; then
        source "${SCRIPT_DIR}/.config"
    fi
}

# Create backup
backup_secret() {
    local secret_name=$1
    local secret_file="${SECRETS_DIR}/${secret_name}"
    
    if [[ ! -f "$secret_file" ]]; then
        echo -e "${YELLOW}Secret not found: $secret_name${NC}"
        return 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${BACKUP_DIR}/${secret_name}.${timestamp}.bak"
    
    cp "$secret_file" "$backup_file"
    chmod 600 "$backup_file"
    
    echo -e "${GREEN}Backed up: $backup_file${NC}"
    
    # Clean old backups
    cleanup_backups "$secret_name"
}

# Cleanup old backups
cleanup_backups() {
    local secret_name=$1
    local keep=${KEEP:-5}
    
    cd "$BACKUP_DIR"
    ls -t "${secret_name}".*.bak 2>/dev/null | tail -n +$((keep + 1)) | xargs -r rm -f
}

# Generate new secret
generate_new_secret() {
    local secret_name=$1
    local length=${SECRET_LENGTH:-32}
    
    case "$secret_name" in
        *jwt*|*session*)
            "${SCRIPT_DIR}/generate_secret.sh" -l 64 -t jwt
            ;;
        *api*|*key*)
            "${SCRIPT_DIR}/generate_secret.sh" -l 32 -t key
            ;;
        *password*|*pass*|*db*)
            "${SCRIPT_DIR}/generate_secret.sh" -l 32
            ;;
        *token*)
            "${SCRIPT_DIR}/generate_secret.sh" -l 64
            ;;
        *)
            "${SCRIPT_DIR}/generate_secret.sh" -l "$length"
            ;;
    esac
}

# Rotate single secret
rotate_secret() {
    local secret_name=$1
    
    echo -e "${BLUE}Rotating: $secret_name${NC}"
    
    # Backup current
    backup_secret "$secret_name" || return 1
    
    # Generate new
    local new_secret=$(generate_new_secret "$secret_name")
    
    # Save new
    echo "$new_secret" > "${SECRETS_DIR}/${secret_name}"
    chmod 600 "${SECRETS_DIR}/${secret_name}"
    
    echo -e "${GREEN}Rotated: $secret_name${NC}"
    
    # Notify
    if [[ "${NOTIFY:-false}" == "true" ]]; then
        notify_rotation "$secret_name"
    fi
}

# Rotate all secrets
rotate_all() {
    echo -e "${BLUE}Rotating all secrets...${NC}"
    
    if [[ ! -d "$SECRETS_DIR" ]]; then
        echo -e "${RED}Secrets directory not found: $SECRETS_DIR${NC}"
        return 1
    fi
    
    for secret_file in "${SECRETS_DIR}"/*; do
        [[ -f "$secret_file" ]] || continue
        
        local secret_name=$(basename "$secret_file")
        rotate_secret "$secret_name"
    done
    
    echo -e "${GREEN}All secrets rotated${NC}"
}

# Notify rotation
notify_rotation() {
    local secret_name=$1
    
    # Slack notification
    if [[ -n "${SLACK_WEBHOOK_URL:-}" ]]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🔄 Secret rotated: ${secret_name}\"}" \
            "$SLACK_WEBHOOK_URL" > /dev/null
    fi
}

# Parse arguments
SECRET=""
ALL=false
KEEP=5
NOTIFY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--secret) SECRET="$2"; shift 2 ;;
        -a|--all) ALL=true; shift ;;
        -k|--keep) KEEP="$2"; shift 2 ;;
        -n|--notify) NOTIFY=true; shift ;;
        -h|--help) usage ;;
        *) shift ;;
    esac
done

# Create directories
mkdir -p "$SECRETS_DIR" "$BACKUP_DIR"

# Load config
load_config

# Main
if [[ "$ALL" == "true" ]]; then
    rotate_all
elif [[ -n "$SECRET" ]]; then
    rotate_secret "$SECRET"
else
    usage
fi
