#!/usr/bin/env bash
set -euo pipefail
NAME="${1:-}"
PATH_VALUE="${2:-}"
ENV_VALUE="${3:-production}"
CONFIG_FILE="${4:-/opt/vps/config/platform.yml}"
[ -n "${NAME}" ] && [ -n "${PATH_VALUE}" ] || { echo "Usage: $0 <name> <path> [environment] [config-file]"; exit 1; }
{
  echo "  - name: ${NAME}"
  echo "    path: ${PATH_VALUE}"
  echo "    environment: ${ENV_VALUE}"
} >> "${CONFIG_FILE}"
echo "Project registered in ${CONFIG_FILE}"
