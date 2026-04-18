#!/usr/bin/env bash
set -euo pipefail
TARGET_DIR="${1:-}"
[ -n "${TARGET_DIR}" ] || { echo "Usage: $0 <service-dir>"; exit 1; }
cd "${TARGET_DIR}"
if [ -f .env.example ] && [ ! -f .env ]; then cp .env.example .env; fi
if [ -f redis.conf.example ] && [ ! -f redis.conf ]; then cp redis.conf.example redis.conf; fi
echo "Initialized service directory: ${TARGET_DIR}"
