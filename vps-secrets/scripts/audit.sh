#!/usr/bin/env bash
# Secrets Audit Script
# Audit secret access, usage, and security

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="${SCRIPT_DIR}/../secrets"
AUDIT_LOG="${SCRIPT_DIR}/../audit.log"

usage() {
    cat << EOF
${BLUE}VPS Secrets Audit${NC}

Usage: $0 [OPTIONS]

Options:
    -r, --report           Generate audit report
    -c, --check           Security check
    -l, --logs            Show access logs
    -o, --output FILE     Output report to file
    -f, --format FORMAT   Report format (text|json|html)
    -h, --help           Show this help

Examples:
    $0 --report            # Generate text report
    $0 --check             # Run security checks
    $0 --logs              # Show access logs
    $0 --report -f json   # JSON report
EOF
    exit 1
}

# Log access
log_access() {
    local action=$1
    local secret=$2
    local user=${USER:-unknown}
    local timestamp=$(date -Iseconds)
    
    echo "[$timestamp] [$user] [$action] $secret" >> "$AUDIT_LOG"
}

# Check file permissions
check_permissions() {
    echo -e "\n${BLUE}[1] File Permissions${NC}"
    
    local issues=0
    
    if [[ -d "$SECRETS_DIR" ]]; then
        local perms=$(stat -c '%a' "$SECRETS_DIR" 2>/dev/null || stat -f '%OLp' "$SECRETS_DIR" 2>/dev/null)
        if [[ "$perms" != "700" ]]; then
            echo -e "${YELLOW}⚠ Secrets directory permissions: $perms (should be 700)${NC}"
            ((issues++))
        else
            echo -e "${GREEN}✓ Secrets directory: OK${NC}"
        fi
        
        for file in "${SECRETS_DIR}"/*; do
            [[ -f "$file" ]] || continue
            local file_perms=$(stat -c '%a' "$file" 2>/dev/null || stat -f '%OLp' "$file" 2>/dev/null)
            if [[ "$file_perms" != "600" ]]; then
                echo -e "${YELLOW}⚠ $(basename $file) permissions: $file_perms (should be 600)${NC}"
                ((issues++))
            fi
        done
    fi
    
    echo "Issues found: $issues"
}

# Check for weak secrets
check_weak_secrets() {
    echo -e "\n${BLUE}[2] Weak Secrets Check${NC}"
    
    local weak=0
    
    if [[ -d "$SECRETS_DIR" ]]; then
        for file in "${SECRETS_DIR}"/*; do
            [[ -f "$file" ]] || continue
            
            local content=$(cat "$file" 2>/dev/null)
            local filename=$(basename "$file")
            
            # Check length
            if [[ ${#content} -lt 16 ]]; then
                echo -e "${YELLOW}⚠ $filename: Too short (< 16 chars)${NC}"
                ((weak++))
            fi
            
            # Check for common weak patterns
            if [[ "$content" =~ ^(password|123456|admin|qwerty) ]]; then
                echo -e "${RED}✗ $filename: Common weak pattern detected${NC}"
                ((weak++))
            fi
        done
    fi
    
    echo "Weak secrets found: $weak"
}

# Check encryption
check_encryption() {
    echo -e "\n${BLUE}[3] Encryption Status${NC}"
    
    local unencrypted=0
    
    if [[ -d "$SECRETS_DIR" ]]; then
        for file in "${SECRETS_DIR}"/*; do
            [[ -f "$file" ]] || continue
            
            if [[ "$file" != *.enc ]] && [[ "$file" != *.gpg ]] && [[ "$file" != *.sops ]]; then
                echo -e "${YELLOW}⚠ $(basename $file): Not encrypted${NC}"
                ((unencrypted++))
            else
                echo -e "${GREEN}✓ $(basename $file): Encrypted${NC}"
            fi
        done
    fi
    
    echo "Unencrypted secrets: $unencrypted"
}

# Check rotation
check_rotation() {
    echo -e "\n${BLUE}[4] Rotation Policy${NC}"
    
    local stale=0
    local max_age=90  # days
    
    if [[ -d "$SECRETS_DIR" ]]; then
        for file in "${SECRETS_DIR}"/*; do
            [[ -f "$file" ]] || continue
            
            local mtime=$(stat -c '%Y' "$file" 2>/dev/null || stat -f '%m' "$file" 2>/dev/null)
            local age=$(( ($(date +%s) - mtime) / 86400 ))
            
            if [[ $age -gt $max_age ]]; then
                echo -e "${YELLOW}⚠ $(basename $file): Not rotated in $age days${NC}"
                ((stale++))
            else
                echo -e "${GREEN}✓ $(basename $file): Last rotated $age days ago${NC}"
            fi
        done
    fi
    
    echo "Stale secrets: $stale"
}

# Check gitignore
check_gitignore() {
    echo -e "\n${BLUE}[5] Git Ignore${NC}"
    
    if [[ -f "${SECRETS_DIR}/../.gitignore" ]]; then
        if grep -q "secrets" "${SECRETS_DIR}/../.gitignore"; then
            echo -e "${GREEN}✓ Secrets in .gitignore${NC}"
        else
            echo -e "${YELLOW}⚠ Add secrets to .gitignore${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ .gitignore not found${NC}"
    fi
}

# Show access logs
show_logs() {
    echo -e "\n${BLUE}Access Logs${NC}"
    
    if [[ -f "$AUDIT_LOG" ]]; then
        tail -50 "$AUDIT_LOG"
    else
        echo "No logs found"
    fi
}

# Generate report
generate_report() {
    local format=${1:-text}
    
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  VPS Secrets Audit Report${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo "Generated: $(date)"
    echo ""
    
    check_permissions
    check_weak_secrets
    check_encryption
    check_rotation
    check_gitignore
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${GREEN}  Audit Complete${NC}"
    echo -e "${BLUE}========================================${NC}"
}

# Run security checks
run_checks() {
    echo -e "${BLUE}Running security checks...${NC}"
    
    generate_report
}

# Main
case "${1:-help}" in
    -r|--report) generate_report "${3:-text}" ;;
    -c|--check) run_checks ;;
    -l|--logs) show_logs ;;
    -h|--help) usage ;;
    *) usage ;;
esac
