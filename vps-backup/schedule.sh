#!/usr/bin/env bash
# Cron Scheduler for VPS Backup
# Setup automated backup schedules

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRONTAB_FILE="${SCRIPT_DIR}/cronjobs.txt"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

usage() {
    cat << EOF
${BLUE}VPS Backup Scheduler${NC}

Usage: $0 <command>

Commands:
    install     Install cron jobs
    remove      Remove all cron jobs
    show        Show current cron jobs
    edit        Edit crontab

Examples:
    $0 install    # Install backup schedules
    $0 show       # View current schedules
    $0 remove     # Remove all backup schedules
EOF
    exit 1
}

show_cronjobs() {
    echo -e "${BLUE}Current Cron Jobs:${NC}"
    echo ""
    crontab -l 2>/dev/null || echo "No cron jobs installed"
}

generate_cronjobs() {
    cat > "${CRONTAB_FILE}" << 'EOF'
# ===========================================
# VPS Backup System - Cron Jobs
# Generated: $(date)
# ===========================================

# Hourly backup (every 6 hours)
0 */6 * * * cd /opt/vps-backup && ./backup.sh run --hourly >> logs/hourly.log 2>&1

# Daily backup (midnight)
0 0 * * * cd /opt/vps-backup && ./backup.sh run --daily >> logs/daily.log 2>&1

# Weekly backup (Sunday midnight)
0 0 * * 0 cd /opt/vps-backup && ./backup.sh run --weekly >> logs/weekly.log 2>&1

# Monthly backup (1st of month midnight)
0 0 1 * * cd /opt/vps-backup && ./backup.sh run --monthly >> logs/monthly.log 2>&1

# Cleanup old backups (daily at 3 AM)
0 3 * * * cd /opt/vps-backup && ./backup.sh cleanup >> logs/cleanup.log 2>&1

# Verify backups (daily at 4 AM)
0 4 * * * cd /opt/vps-backup && ./backup.sh verify >> logs/verify.log 2>&1
EOF
}

install_cronjobs() {
    echo -e "${BLUE}Installing VPS Backup cron jobs...${NC}"
    
    # Create backup directory
    mkdir -p "${SCRIPT_DIR}/logs"
    
    # Generate cron file
    generate_cronjobs
    
    # Backup existing crontab
    if crontab -l &>/dev/null; then
        echo -e "${YELLOW}Backing up existing crontab...${NC}"
        crontab -l > "${SCRIPT_DIR}/crontab.backup"
    fi
    
    # Add cron jobs
    crontab - << 'EOF'
# ===========================================
# VPS Backup System - Cron Jobs
# ===========================================

# Hourly backup (every 6 hours)
0 */6 * * * cd /opt/vps-backup && ./backup.sh run --hourly >> logs/hourly.log 2>&1

# Daily backup (midnight)
0 0 * * * cd /opt/vps-backup && ./backup.sh run --daily >> logs/daily.log 2>&1

# Weekly backup (Sunday midnight)
0 0 * * 0 cd /opt/vps-backup && ./backup.sh run --weekly >> logs/weekly.log 2>&1

# Monthly backup (1st of month midnight)
0 0 1 * * cd /opt/vps-backup && ./backup.sh run --monthly >> logs/monthly.log 2>&1

# Cleanup old backups (daily at 3 AM)
0 3 * * * cd /opt/vps-backup && ./backup.sh cleanup >> logs/cleanup.log 2>&1

# Verify backups (daily at 4 AM)
0 4 * * * cd /opt/vps-backup && ./backup.sh verify >> logs/verify.log 2>&1
EOF
    
    echo -e "${GREEN}Cron jobs installed successfully!${NC}"
    echo ""
    echo "Schedule:"
    echo "  Hourly:  0,6,12,18 * * * *"
    echo "  Daily:   0 0 * * *"
    echo "  Weekly:  0 0 * * 0"
    echo "  Monthly: 0 0 1 * *"
    echo "  Cleanup: 0 3 * * *"
    echo "  Verify:  0 4 * * *"
}

remove_cronjobs() {
    echo -e "${YELLOW}Removing VPS Backup cron jobs...${NC}"
    
    # Get current crontab
    local current=$(crontab -l 2>/dev/null || true)
    
    # Remove backup-related lines
    local filtered=$(echo "$current" | grep -v "vps-backup\|backup.sh")
    
    # Update crontab
    if [[ -n "$filtered" ]]; then
        echo "$filtered" | crontab -
        echo -e "${GREEN}Cron jobs removed${NC}"
    else
        crontab -r 2>/dev/null || true
        echo -e "${GREEN}Crontab cleared${NC}"
    fi
}

# Main
case "${1:-help}" in
    install) install_cronjobs ;;
    remove) remove_cronjobs ;;
    show) show_cronjobs ;;
    edit) crontab -e ;;
    help|--help|-h) usage ;;
    *) usage ;;
esac
