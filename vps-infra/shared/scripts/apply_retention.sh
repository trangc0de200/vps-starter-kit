#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-/opt/vps/backups/daily}"
DAYS="${2:-14}"

echo "Applying retention: removing files older than ${DAYS} days in ${TARGET_DIR}"
find "${TARGET_DIR}" -type f -mtime +"${DAYS}" -print -delete
