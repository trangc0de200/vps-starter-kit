#!/usr/bin/env bash
set -euo pipefail
CONFIG_FILE="${1:-./config/platform.yml}"
[ -f "${CONFIG_FILE}" ] || { echo "Config not found: ${CONFIG_FILE}"; exit 1; }
echo "Config file found: ${CONFIG_FILE}"
grep -nE "^platform:|^networks:|^defaults:|^projects:|^services:|^plugins:|^alerting:|^secrets:" "${CONFIG_FILE}" || true
