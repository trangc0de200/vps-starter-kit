#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

log() { printf '\n[%s] %s\n' "$(date '+%F %T')" "$*"; }
die() { printf '\n[ERROR] %s\n' "$*" >&2; exit 1; }

require_root() {
  [ "${EUID}" -eq 0 ] || die "Please run with sudo or as root."
}

detect_os() {
  [ -f /etc/os-release ] || die "Cannot detect OS."
  . /etc/os-release
  [ "${ID:-}" = "ubuntu" ] || die "Ubuntu is required."
  if [ "${VERSION_ID:-}" != "24.04" ]; then
    log "Warning: this script was designed for Ubuntu 24.04, detected ${PRETTY_NAME:-unknown}."
  fi
}

summary() {
  cat <<EOF

Bootstrap configuration:
  BOOTSTRAP_USER       = ${BOOTSTRAP_USER}
  VPS_ROOT             = ${VPS_ROOT}
  INSTALL_NPM          = ${INSTALL_NPM}
  AUTO_START_NPM       = ${AUTO_START_NPM}
  ENABLE_UFW           = ${ENABLE_UFW}
  ENABLE_FAIL2BAN      = ${ENABLE_FAIL2BAN}
  INSTALL_CRON_EXAMPLES= ${INSTALL_CRON_EXAMPLES}
  TZ_VALUE             = ${TZ_VALUE}
  PROXY_NETWORK        = ${PROXY_NETWORK}
  DB_NETWORK           = ${DB_NETWORK}

EOF
}

confirm() {
  if [ -t 0 ]; then
    read -r -p "Continue? [y/N]: " ans
    case "${ans}" in
      y|Y|yes|YES) ;;
      *) die "Cancelled." ;;
    esac
  fi
}

update_system() {
  log "Updating system..."
  apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
}

install_base_packages() {
  log "Installing base packages..."
  DEBIAN_FRONTEND=noninteractive apt-get install -y     curl wget git unzip rsync ca-certificates gnupg lsb-release     ufw fail2ban cron jq htop net-tools software-properties-common
}

set_timezone() {
  log "Setting timezone to ${TZ_VALUE}..."
  timedatectl set-timezone "${TZ_VALUE}" || true
}

install_docker() {
  if command -v docker >/dev/null 2>&1; then
    log "Docker already installed. Skipping installation."
  else
    log "Installing Docker..."
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo       "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu       $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list

    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y       docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  systemctl enable docker
  systemctl start docker
  docker --version
  docker compose version
}

create_user() {
  if id "${BOOTSTRAP_USER}" >/dev/null 2>&1; then
    log "User ${BOOTSTRAP_USER} already exists."
  else
    log "Creating user ${BOOTSTRAP_USER}..."
    adduser --disabled-password --gecos "" "${BOOTSTRAP_USER}"
  fi

  usermod -aG sudo "${BOOTSTRAP_USER}"
  usermod -aG docker "${BOOTSTRAP_USER}"
}

configure_ufw() {
  [ "${ENABLE_UFW}" = "yes" ] || { log "Skipping UFW."; return; }

  log "Configuring UFW..."
  ufw allow OpenSSH
  ufw allow 80/tcp
  ufw allow 443/tcp
  if [ "${INSTALL_NPM}" = "yes" ]; then
    ufw allow 81/tcp
  fi
  ufw --force enable
  ufw status verbose || true
}

configure_fail2ban() {
  [ "${ENABLE_FAIL2BAN}" = "yes" ] || { log "Skipping Fail2Ban."; return; }

  log "Enabling Fail2Ban..."
  systemctl enable fail2ban
  systemctl restart fail2ban
}

create_layout() {
  log "Creating VPS folder layout at ${VPS_ROOT}..."
  mkdir -p "${VPS_ROOT}"
  mkdir -p "${VPS_ROOT}/backups"/{postgres,mysql,redis,sqlserver,npm,daily,weekly,monthly}
  mkdir -p "${VPS_ROOT}/logs"
  mkdir -p "${VPS_ROOT}/scripts"

  rsync -a --delete     --exclude ".git"     --exclude ".github"     "${REPO_DIR}/vps-app" "${REPO_DIR}/vps-db" "${REPO_DIR}/vps-infra" "${REPO_DIR}/docs" "${VPS_ROOT}/"

  chown -R "${BOOTSTRAP_USER}:${BOOTSTRAP_USER}" "${VPS_ROOT}"
}

create_networks() {
  log "Creating Docker networks if missing..."
  docker network inspect "${PROXY_NETWORK}" >/dev/null 2>&1 || docker network create "${PROXY_NETWORK}"
  docker network inspect "${DB_NETWORK}" >/dev/null 2>&1 || docker network create "${DB_NETWORK}"
}

prepare_redis_conf() {
  local redis_dir="${VPS_ROOT}/vps-db/redis"
  if [ -f "${redis_dir}/redis.conf.example" ] && [ ! -f "${redis_dir}/redis.conf" ]; then
    cp "${redis_dir}/redis.conf.example" "${redis_dir}/redis.conf"
  fi
}

maybe_disable_npm() {
  if [ "${INSTALL_NPM}" != "yes" ]; then
    log "INSTALL_NPM=no, removing NPM scaffold from target."
    rm -rf "${VPS_ROOT}/vps-infra/nginx-proxy-manager"
  fi
}

create_shared_scripts() {
  log "Ensuring shared helper scripts are executable..."
  if [ -d "${VPS_ROOT}/vps-infra/shared/scripts" ]; then
    find "${VPS_ROOT}/vps-infra/shared/scripts" -type f -name "*.sh" -exec chmod +x {} \;
  fi
  chown -R "${BOOTSTRAP_USER}:${BOOTSTRAP_USER}" "${VPS_ROOT}/vps-infra/shared"
}

install_cron_examples() {
  [ "${INSTALL_CRON_EXAMPLES}" = "yes" ] || { log "Skipping cron examples."; return; }
  chown -R "${BOOTSTRAP_USER}:${BOOTSTRAP_USER}" "${VPS_ROOT}/vps-infra/shared/cron"
}

auto_start_npm() {
  if [ "${INSTALL_NPM}" = "yes" ] && [ "${AUTO_START_NPM}" = "yes" ]; then
    log "Auto-starting Nginx Proxy Manager..."
    cd "${VPS_ROOT}/vps-infra/nginx-proxy-manager"
    docker compose up -d
  fi
}

final_notes() {
  cat <<EOF

Bootstrap completed successfully.

Next steps:
  1. Add your SSH public key:
       /home/${BOOTSTRAP_USER}/.ssh/authorized_keys

  2. Switch user:
       su - ${BOOTSTRAP_USER}

  3. If NPM was not auto-started:
       cd ${VPS_ROOT}/vps-infra/nginx-proxy-manager
       docker compose up -d

  4. Open:
       http://YOUR_SERVER_IP:81

  5. Change default NPM admin credentials immediately.

  6. Start the DB/cache services you need:
       cd ${VPS_ROOT}/vps-db/postgres && cp .env.example .env && nano .env && docker compose up -d
       cd ${VPS_ROOT}/vps-db/mysql && cp .env.example .env && nano .env && docker compose up -d
       cd ${VPS_ROOT}/vps-db/redis && cp .env.example .env && cp redis.conf.example redis.conf && nano .env && docker compose up -d
       cd ${VPS_ROOT}/vps-db/sqlserver && cp .env.example .env && nano .env && docker compose up -d

  7. Create a new app from template:
       cp -r ${VPS_ROOT}/vps-app/app-template ${VPS_ROOT}/vps-app/my-app

  8. Review:
       ${VPS_ROOT}/docs/OPERATIONS.md
       ${VPS_ROOT}/docs/SECURITY.md
       ${VPS_ROOT}/docs/BACKUP_AND_RESTORE.md
       ${VPS_ROOT}/docs/CICD_V3.md
       ${VPS_ROOT}/docs/DISASTER_RECOVERY.md

EOF
}

main() {
  require_root
  detect_os
  summary
  confirm
  update_system
  install_base_packages
  set_timezone
  install_docker
  create_user
  configure_ufw
  configure_fail2ban
  create_layout
  create_networks
  prepare_redis_conf
  maybe_disable_npm
  create_shared_scripts
  install_cron_examples
  auto_start_npm
  final_notes
}

main "$@"
