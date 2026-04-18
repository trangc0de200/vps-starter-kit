#!/usr/bin/env bash
set -euo pipefail
NAME="${1:-}"
PATH_VALUE="${2:-}"
CONFIG_FILE="${3:-/opt/vps/config/platform.yml}"
[ -n "${NAME}" ] && [ -n "${PATH_VALUE}" ] || { echo "Usage: $0 <name> <path> [config-file]"; exit 1; }
{
  echo "  - name: ${NAME}"
  echo "    path: ${PATH_VALUE}"
} >> "${CONFIG_FILE}"
echo "Service registered in ${CONFIG_FILE}"
