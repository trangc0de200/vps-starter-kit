#!/usr/bin/env bash
set -euo pipefail
TARGET_DIR="${1:-/opt/vps/backups/daily}"
DAYS="${2:-14}"
find "${TARGET_DIR}" -type f -mtime +"${DAYS}" -print -delete
