#!/usr/bin/env bash
# =============================================================================
# VPS Starter Kit - Bootstrap Script
# =============================================================================
# A production-ready VPS bootstrap script for Ubuntu 24.04
# Installs Docker, configures security, and sets up the VPS platform
#
# Usage:
#   sudo ./install.sh                    # Interactive mode
#   sudo ./install.sh --non-interactive # Non-interactive mode
#   sudo ./install.sh --help            # Show help
#
# Environment Variables:
#   BOOTSTRAP_USER        Deploy user name (default: deployer)
#   VPS_ROOT              Platform root directory (default: /opt/vps)
#   INSTALL_NPM           Install Nginx Proxy Manager (default: yes)
#   AUTO_START_NPM        Auto-start NPM after install (default: yes)
#   ENABLE_UFW            Enable UFW firewall (default: yes)
#   ENABLE_FAIL2BAN       Enable Fail2Ban (default: yes)
#   TZ_VALUE              Timezone (default: UTC)
#   PROXY_NETWORK        Docker proxy network (default: proxy_network)
#   DB_NETWORK            Docker database network (default: db_network)
# =============================================================================

set -Eeuo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration
BOOTSTRAP_USER="${BOOTSTRAP_USER:-deployer}"
VPS_ROOT="${VPS_ROOT:-/opt/vps}"
INSTALL_NPM="${INSTALL_NPM:-yes}"
AUTO_START_NPM="${AUTO_START_NPM:-yes}"
ENABLE_UFW="${ENABLE_UFW:-yes}"
ENABLE_FAIL2BAN="${ENABLE_FAIL2BAN:-yes}"
INSTALL_CRON_EXAMPLES="${INSTALL_CRON_EXAMPLES:-yes}"
TZ_VALUE="${TZ_VALUE:-UTC}"
PROXY_NETWORK="${PROXY_NETWORK:-proxy_network}"
DB_NETWORK="${DB_NETWORK:-db_network}"
NON_INTERACTIVE="${NON_INTERACTIVE:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

separator() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# =============================================================================
# PREREQUISITE CHECKS
# =============================================================================

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "This script must be run as root or with sudo"
        log_info "Usage: sudo $0"
        exit 1
    fi
}

detect_os() {
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect OS: /etc/os-release not found"
        exit 1
    fi

    . /etc/os-release

    if [[ "${ID:-}" != "ubuntu" ]]; then
        log_error "This script requires Ubuntu, detected: ${ID:-unknown}"
        exit 1
    fi

    # Check for Ubuntu 24.04
    local version_id="${VERSION_ID:-}"
    if [[ ! "$version_id" =~ ^(24\.04|24\.10|22\.04|22\.10)$ ]]; then
        log_warn "This script is optimized for Ubuntu 24.04/22.04"
        log_warn "Detected version: ${VERSION_ID}"
    fi

    log_info "Detected: ${PRETTY_NAME}"
}

confirm() {
    if [[ "${NON_INTERACTIVE}" == "true" ]]; then
        return 0
    fi

    if [[ ! -t 0 ]]; then
        # Non-interactive terminal, skip confirmation
        return 0
    fi

    echo ""
    read -r -p "Continue with installation? [y/N]: " ans
    case "${ans}" in
        y|Y|yes|YES)
            return 0
            ;;
        *)
            log_info "Installation cancelled by user"
            exit 0
            ;;
    esac
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    local missing=()

    # Check for required commands
    for cmd in curl wget git rsync; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_warn "Missing commands: ${missing[*]}"
        log_info "These will be installed during the setup"
    fi

    # Check disk space (minimum 10GB)
    local available_space
    available_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    if [[ "$available_space" -lt 10 ]]; then
        log_warn "Low disk space: ${available_space}GB available"
        log_warn "Recommended: at least 10GB free space"
    fi

    log_success "Prerequisites check complete"
}

# =============================================================================
# SYSTEM UPDATE & PACKAGES
# =============================================================================

update_system() {
    separator
    log_info "Updating system packages..."

    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y
    apt-get upgrade -y

    log_success "System packages updated"
}

install_base_packages() {
    separator
    log_info "Installing base packages..."

    local packages=(
        curl
        wget
        git
        unzip
        rsync
        ca-certificates
        gnupg
        lsb-release
        ufw
        fail2ban
        cron
        jq
        htop
        net-tools
        software-properties-common
        openssl
        bc
        netcat
        iputils-ping
        dnsutils
    )

    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y "${packages[@]}"

    log_success "Base packages installed"
}

set_timezone() {
    separator
    log_info "Setting timezone to: ${TZ_VALUE}"

    timedatectl set-timezone "${TZ_VALUE}" || {
        log_warn "Failed to set timezone, keeping current"
    }

    # Enable NTP
    timedatectl set-ntp true || true

    log_success "Timezone configured"
}

# =============================================================================
# DOCKER INSTALLATION
# =============================================================================

install_docker() {
    separator

    if command -v docker >/dev/null 2>&1; then
        local docker_version
        docker_version=$(docker --version | awk '{print $3}' | tr -d ',')
        log_info "Docker already installed: ${docker_version}"
        return 0
    fi

    log_info "Installing Docker Engine..."

    # Create directory for keyrings
    install -m 0755 -d /etc/apt/keyrings

    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    local arch
    arch=$(dpkg --print-architecture)
    echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
        > /etc/apt/sources.list.d/docker.list

    # Install Docker
    apt-get update -y
    export DEBIAN_FRONTEND=noninteractive
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Enable and start Docker
    systemctl enable docker
    systemctl start docker

    # Verify installation
    if docker --version >/dev/null 2>&1; then
        log_success "Docker installed: $(docker --version)"
    else
        log_error "Docker installation failed"
        exit 1
    fi
}

configure_docker() {
    # Configure Docker daemon
    mkdir -p /etc/docker

    cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true
}
EOF

    systemctl restart docker
    log_info "Docker daemon configured"
}

# =============================================================================
# USER MANAGEMENT
# =============================================================================

create_user() {
    separator
    log_info "Creating deploy user: ${BOOTSTRAP_USER}"

    if id "${BOOTSTRAP_USER}" >/dev/null 2>&1; then
        log_info "User ${BOOTSTRAP_USER} already exists"
    else
        adduser --disabled-password --gecos "" "${BOOTSTRAP_USER}"
        log_success "User ${BOOTSTRAP_USER} created"
    fi

    # Add to groups
    usermod -aG sudo "${BOOTSTRAP_USER}"
    usermod -aG docker "${BOOTSTRAP_USER}"

    # Configure sudo for passwordless operation
    echo "${BOOTSTRAP_USER} ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/systemctl, /usr/bin/docker" \
        > /etc/sudoers.d/${BOOTSTRAP_USER}
    chmod 440 /etc/sudoers.d/${BOOTSTRAP_USER}

    log_success "User ${BOOTSTRAP_USER} configured"
}

# =============================================================================
# FIREWALL CONFIGURATION
# =============================================================================

configure_ufw() {
    separator

    if [[ "${ENABLE_UFW}" != "yes" ]]; then
        log_info "UFW configuration skipped (ENABLE_UFW=no)"
        return 0
    fi

    log_info "Configuring UFW firewall..."

    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing

    # Allow SSH (critical to not lock yourself out!)
    ufw allow OpenSSH

    # Allow HTTP/HTTPS
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'

    # Allow Nginx Proxy Manager
    if [[ "${INSTALL_NPM}" == "yes" ]]; then
        ufw allow 81/tcp comment 'NPM Admin'
    fi

    # Enable UFW
    echo "y" | ufw enable || {
        log_warn "Failed to enable UFW, continuing without firewall"
    }

    # Show status
    ufw status numbered

    log_success "UFW firewall configured"
}

# =============================================================================
# FAIL2BAN CONFIGURATION
# =============================================================================

configure_fail2ban() {
    separator

    if [[ "${ENABLE_FAIL2BAN}" != "yes" ]]; then
        log_info "Fail2Ban configuration skipped (ENABLE_FAIL2BAN=no)"
        return 0
    fi

    log_info "Configuring Fail2Ban..."

    # Create Fail2Ban configuration
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sender = fail2ban@localhost
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 86400

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban

    # Verify
    if systemctl is-active --quiet fail2ban; then
        log_success "Fail2Ban configured and running"
    else
        log_warn "Fail2Ban failed to start"
    fi
}

# =============================================================================
# DIRECTORY STRUCTURE & FILES
# =============================================================================

create_layout() {
    separator
    log_info "Creating platform directory structure..."

    # Create base directories
    mkdir -p "${VPS_ROOT}"
    mkdir -p "${VPS_ROOT}/backups"/{postgres,mysql,redis,sqlserver,npm,daily,weekly,monthly}
    mkdir -p "${VPS_ROOT}/logs"
    mkdir -p "${VPS_ROOT}/scripts"
    mkdir -p "${VPS_ROOT}/certs"
    mkdir -p "${VPS_ROOT}/data"

    # Sync platform files
    log_info "Copying platform files to ${VPS_ROOT}..."

    local dirs_to_sync=(
        vps-app
        vps-db
        vps-infra
        vps-monitoring
        vps-security
        vps-secrets
        vps-alerting
        vps-platform
        plugins
        docs
        config
    )

    for dir in "${dirs_to_sync[@]}"; do
        if [[ -d "${REPO_DIR}/${dir}" ]]; then
            rsync -a --delete \
                --exclude ".git" \
                --exclude ".github" \
                "${REPO_DIR}/${dir}/" "${VPS_ROOT}/${dir}/"
            log_info "  Synced: ${dir}"
        fi
    done

    # Copy CLI tools
    cp "${REPO_DIR}/vps-cli" "${VPS_ROOT}/scripts/vps-cli"
    chmod +x "${VPS_ROOT}/scripts/vps-cli"

    # Copy helper scripts from vps-infra/shared/scripts
    if [[ -d "${VPS_ROOT}/vps-infra/shared/scripts" ]]; then
        cp "${VPS_ROOT}/vps-infra/shared/scripts/create_app.sh" "${VPS_ROOT}/scripts/create-app.sh" 2>/dev/null || true
        cp "${VPS_ROOT}/vps-infra/shared/scripts/register_project.sh" "${VPS_ROOT}/scripts/register-project.sh" 2>/dev/null || true
        cp "${VPS_ROOT}/vps-infra/shared/scripts/register_service.sh" "${VPS_ROOT}/scripts/register-service.sh" 2>/dev/null || true
        chmod +x "${VPS_ROOT}/scripts/create-app.sh" "${VPS_ROOT}/scripts/register-project.sh" "${VPS_ROOT}/scripts/register-service.sh" 2>/dev/null || true
    fi

    # Set ownership
    chown -R "${BOOTSTRAP_USER}:${BOOTSTRAP_USER}" "${VPS_ROOT}"

    log_success "Platform directory structure created"
}

prepare_redis_conf() {
    local redis_dir="${VPS_ROOT}/vps-db/redis"

    if [[ -f "${redis_dir}/redis.conf.example" ]] && [[ ! -f "${redis_dir}/redis.conf" ]]; then
        cp "${redis_dir}/redis.conf.example" "${redis_dir}/redis.conf"
        log_info "Redis configuration prepared"
    fi
}

# =============================================================================
# DOCKER NETWORKS
# =============================================================================

create_networks() {
    separator
    log_info "Creating Docker networks..."

    # Proxy network
    if ! docker network inspect "${PROXY_NETWORK}" >/dev/null 2>&1; then
        docker network create "${PROXY_NETWORK}"
        log_info "  Created: ${PROXY_NETWORK}"
    else
        log_info "  Exists: ${PROXY_NETWORK}"
    fi

    # Database network
    if ! docker network inspect "${DB_NETWORK}" >/dev/null 2>&1; then
        docker network create "${DB_NETWORK}"
        log_info "  Created: ${DB_NETWORK}"
    else
        log_info "  Exists: ${DB_NETWORK}"
    fi

    log_success "Docker networks configured"
}

# =============================================================================
# NGINX PROXY MANAGER
# =============================================================================

maybe_disable_npm() {
    if [[ "${INSTALL_NPM}" != "yes" ]]; then
        log_info "Removing Nginx Proxy Manager (INSTALL_NPM=no)"
        rm -rf "${VPS_ROOT}/vps-infra/nginx-proxy-manager"
    fi
}

auto_start_npm() {
    if [[ "${INSTALL_NPM}" != "yes" ]] || [[ "${AUTO_START_NPM}" != "yes" ]]; then
        return 0
    fi

    separator
    log_info "Starting Nginx Proxy Manager..."

    cd "${VPS_ROOT}/vps-infra/nginx-proxy-manager"

    # Create necessary directories
    mkdir -p data/
    mkdir -p letsencrypt/

    docker compose up -d

    # Wait for NPM to be ready
    log_info "Waiting for Nginx Proxy Manager to start..."
    sleep 5

    if docker ps --format '{{.Names}}' | grep -q "nginx-proxy-manager"; then
        log_success "Nginx Proxy Manager started"
        log_info "Admin UI: http://$(hostname -I | awk '{print $1}'):81"
        log_info "Default credentials: admin@example.com / changeme"
    else
        log_warn "Nginx Proxy Manager may not have started correctly"
        log_info "Check logs with: docker compose logs -f"
    fi
}

# =============================================================================
# PERMISSIONS & CLEANUP
# =============================================================================

ensure_exec_scripts() {
    find "${VPS_ROOT}" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
}

create_cron_examples() {
    if [[ "${INSTALL_CRON_EXAMPLES}" != "yes" ]]; then
        return 0
    fi

    separator
    log_info "Creating cron job examples..."

    cat > "${VPS_ROOT}/scripts/cron-examples.sh" << 'CRONEOF'
#!/bin/bash
# Cron Job Examples for VPS Starter Kit
# Add these to crontab with: crontab -e

# Health check every 5 minutes
# */5 * * * * /opt/vps/scripts/vps-cli check-containers >> /var/log/vps-health.log 2>&1

# Backup databases daily at 2 AM
# 0 2 * * * cd /opt/vps && ./scripts/backup-db.sh all >> /var/log/backup.log 2>&1

# Cleanup old logs weekly
# 0 3 * * 0 find /opt/vps/logs -name "*.log" -mtime +30 -delete

# Check SSL certificates weekly
# 0 4 * * 0 /opt/vps/scripts/vps-cli check-ssl yourdomain.com >> /var/log/ssl-check.log 2>&1

# Registry report daily
# 0 6 * * * cd /opt/vps/vps-platform && ./scripts/registry_report.sh --generate
CRONEOF

    chmod +x "${VPS_ROOT}/scripts/cron-examples.sh"

    log_success "Cron examples created"
}

# =============================================================================
# VERIFICATION
# =============================================================================

verify_installation() {
    separator
    log_info "Verifying installation..."

    local errors=0

    # Check Docker
    if docker ps >/dev/null 2>&1; then
        log_success "Docker is running"
    else
        log_error "Docker is not running"
        ((errors++))
    fi

    # Check user
    if id "${BOOTSTRAP_USER}" >/dev/null 2>&1; then
        log_success "User ${BOOTSTRAP_USER} exists"
    else
        log_error "User ${BOOTSTRAP_USER} not found"
        ((errors++))
    fi

    # Check directories
    if [[ -d "${VPS_ROOT}" ]]; then
        log_success "VPS root exists: ${VPS_ROOT}"
    else
        log_error "VPS root not found: ${VPS_ROOT}"
        ((errors++))
    fi

    # Check networks
    if docker network inspect "${PROXY_NETWORK}" >/dev/null 2>&1; then
        log_success "Proxy network exists"
    else
        log_warn "Proxy network not found"
    fi

    return $errors
}

# =============================================================================
# FINAL MESSAGES
# =============================================================================

print_summary() {
    separator
    echo -e "${BOLD}Installation Complete!${NC}"
    separator

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  VPS Platform Bootstrap Summary${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${BOLD}Platform Root:${NC}    ${VPS_ROOT}"
    echo -e "  ${BOLD}Deploy User:${NC}      ${BOOTSTRAP_USER}"
    echo -e "  ${BOLD}Docker Network:${NC}   ${PROXY_NETWORK}, ${DB_NETWORK}"
    echo ""
    echo -e "${CYAN}  Next Steps:${NC}"
    echo ""
    echo -e "  1. Login as deploy user:"
    echo -e "     ${YELLOW}sudo su - ${BOOTSTRAP_USER}${NC}"
    echo ""
    echo -e "  2. Use the CLI tool:"
    echo -e "     ${YELLOW}cd ${VPS_ROOT} && ./vps-cli status${NC}"
    echo ""
    echo -e "  3. Start services:"
    echo -e "     ${YELLOW}cd ${VPS_ROOT}/vps-infra/nginx-proxy-manager && docker compose up -d${NC}"
    echo ""
    echo -e "  4. View available commands:"
    echo -e "     ${YELLOW}./vps-cli help${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_troubleshooting() {
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  Troubleshooting${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  If you encounter issues:"
    echo ""
    echo -e "  • Check Docker status:"
    echo -e "    ${YELLOW}sudo systemctl status docker${NC}"
    echo ""
    echo -e "  • View container logs:"
    echo -e "    ${YELLOW}docker compose -f ${VPS_ROOT}/vps-infra/nginx-proxy-manager/docker-compose.yml logs${NC}"
    echo ""
    echo -e "  • Restart Docker:"
    echo -e "    ${YELLOW}sudo systemctl restart docker${NC}"
    echo ""
    echo -e "  • Check firewall:"
    echo -e "    ${YELLOW}sudo ufw status${NC}"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================

show_help() {
    cat << 'HELPEOF'
VPS Starter Kit - Bootstrap Script

Usage:
    sudo ./install.sh [OPTIONS]

Options:
    --non-interactive    Run without prompts
    --help              Show this help message

Environment Variables:
    BOOTSTRAP_USER        Deploy user name (default: deployer)
    VPS_ROOT              Platform root directory (default: /opt/vps)
    INSTALL_NPM           Install Nginx Proxy Manager (default: yes)
    AUTO_START_NPM        Auto-start NPM after install (default: yes)
    ENABLE_UFW            Enable UFW firewall (default: yes)
    ENABLE_FAIL2BAN       Enable Fail2Ban (default: yes)
    INSTALL_CRON_EXAMPLES  Install cron examples (default: yes)
    TZ_VALUE              Timezone (default: UTC)
    PROXY_NETWORK         Docker proxy network (default: proxy_network)
    DB_NETWORK            Docker database network (default: db_network)

Examples:
    # Default installation
    sudo ./install.sh

    # Non-interactive
    sudo ./install.sh --non-interactive

    # Custom configuration
    sudo BOOTSTRAP_USER=myuser \
         VPS_ROOT=/opt/myplatform \
         INSTALL_NPM=yes \
         ./install.sh

    # Skip optional components
    sudo ENABLE_UFW=no \
         ENABLE_FAIL2BAN=no \
         ./install.sh
HELPEOF
}

main() {
    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --help|-h)
                show_help
                exit 0
                ;;
            --non-interactive)
                NON_INTERACTIVE=true
                ;;
        esac
    done

    clear
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}       ${BOLD}VPS Starter Kit Bootstrap${NC}                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}       ${BOLD}Ubuntu 24.04 Production Platform${NC}                           ${CYAN}║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Run installation steps
    require_root
    detect_os
    check_prerequisites
    confirm

    separator
    log_info "Starting installation..."

    update_system
    install_base_packages
    set_timezone
    install_docker
    configure_docker
    create_user
    configure_ufw
    configure_fail2ban
    create_layout
    create_networks
    prepare_redis_conf
    maybe_disable_npm
    ensure_exec_scripts
    create_cron_examples
    auto_start_npm

    separator
    verify_installation
    print_summary
    print_troubleshooting

    separator
    log_success "Bootstrap completed successfully!"
}

main "$@"
