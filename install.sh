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

require_root(){ [ "${EUID}" -eq 0 ] || { echo "Run with sudo or as root."; exit 1; }; }
detect_os(){ . /etc/os-release; [ "${ID:-}" = "ubuntu" ] || { echo "Ubuntu required."; exit 1; }; }
confirm(){ if [ -t 0 ]; then read -r -p "Continue? [y/N]: " ans; case "${ans}" in y|Y|yes|YES) ;; *) exit 1 ;; esac; fi; }

update_system(){ apt-get update -y; DEBIAN_FRONTEND=noninteractive apt-get upgrade -y; }
install_base_packages(){ DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget git unzip rsync ca-certificates gnupg lsb-release ufw fail2ban cron jq htop net-tools software-properties-common openssl; }
set_timezone(){ timedatectl set-timezone "${TZ_VALUE}" || true; }

install_docker(){
  if ! command -v docker >/dev/null 2>&1; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
  systemctl enable docker
  systemctl start docker
}

create_user(){
  if ! id "${BOOTSTRAP_USER}" >/dev/null 2>&1; then
    adduser --disabled-password --gecos "" "${BOOTSTRAP_USER}"
  fi
  usermod -aG sudo "${BOOTSTRAP_USER}"
  usermod -aG docker "${BOOTSTRAP_USER}"
}

configure_ufw(){
  [ "${ENABLE_UFW}" = "yes" ] || return 0
  ufw allow OpenSSH
  ufw allow 80/tcp
  ufw allow 443/tcp
  [ "${INSTALL_NPM}" = "yes" ] && ufw allow 81/tcp || true
  ufw --force enable
}

configure_fail2ban(){
  [ "${ENABLE_FAIL2BAN}" = "yes" ] || return 0
  systemctl enable fail2ban
  systemctl restart fail2ban
}

create_layout(){
  mkdir -p "${VPS_ROOT}"
  mkdir -p "${VPS_ROOT}/backups"/{postgres,mysql,redis,sqlserver,npm,daily,weekly,monthly}
  mkdir -p "${VPS_ROOT}/logs" "${VPS_ROOT}/scripts"
  rsync -a --delete --exclude ".git" --exclude ".github"     "${REPO_DIR}/vps-app" "${REPO_DIR}/vps-db" "${REPO_DIR}/vps-infra" "${REPO_DIR}/vps-monitoring" "${REPO_DIR}/vps-security" "${REPO_DIR}/plugins" "${REPO_DIR}/docs" "${REPO_DIR}/config" "${VPS_ROOT}/"
  cp "${REPO_DIR}/vps-cli" "${VPS_ROOT}/scripts/vps-cli"
  chmod +x "${VPS_ROOT}/scripts/vps-cli"
  chown -R "${BOOTSTRAP_USER}:${BOOTSTRAP_USER}" "${VPS_ROOT}"
}

create_networks(){
  docker network inspect "${PROXY_NETWORK}" >/dev/null 2>&1 || docker network create "${PROXY_NETWORK}"
  docker network inspect "${DB_NETWORK}" >/dev/null 2>&1 || docker network create "${DB_NETWORK}"
}

prepare_redis_conf(){
  local redis_dir="${VPS_ROOT}/vps-db/redis"
  if [ -f "${redis_dir}/redis.conf.example" ] && [ ! -f "${redis_dir}/redis.conf" ]; then
    cp "${redis_dir}/redis.conf.example" "${redis_dir}/redis.conf"
  fi
}

maybe_disable_npm(){ [ "${INSTALL_NPM}" = "yes" ] || rm -rf "${VPS_ROOT}/vps-infra/nginx-proxy-manager"; }
ensure_exec_scripts(){ find "${VPS_ROOT}" -type f -name "*.sh" -exec chmod +x {} \; || true; }
auto_start_npm(){ if [ "${INSTALL_NPM}" = "yes" ] && [ "${AUTO_START_NPM}" = "yes" ]; then cd "${VPS_ROOT}/vps-infra/nginx-proxy-manager" && docker compose up -d; fi; }

main(){
  require_root
  detect_os
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
  ensure_exec_scripts
  auto_start_npm
  echo "Bootstrap completed successfully."
}
main "$@"
