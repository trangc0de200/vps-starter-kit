#!/usr/bin/env bash
set -euo pipefail
CONFIG_FILE="${1:-/opt/vps/config/platform.yml}"
[ -f "${CONFIG_FILE}" ] || { echo "Config not found: ${CONFIG_FILE}"; exit 1; }
echo "Registry report from ${CONFIG_FILE}"
grep -nE "^projects:|^services:|^plugins:|^alerting:|^secrets:" "${CONFIG_FILE}" || true
