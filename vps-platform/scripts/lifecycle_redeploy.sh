#!/usr/bin/env bash
set -euo pipefail
DIR="${1:-}"
[ -n "${DIR}" ] || { echo "Usage: $0 <compose-dir>"; exit 1; }
cd "${DIR}"
docker compose up -d --build
