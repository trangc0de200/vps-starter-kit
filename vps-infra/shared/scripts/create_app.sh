#!/usr/bin/env bash
set -euo pipefail
APP_NAME="${1:-}"
ROOT="${ROOT:-/opt/vps}"
[ -n "${APP_NAME}" ] || { echo "Usage: $0 <app-name>"; exit 1; }
TARGET_DIR="${ROOT}/vps-app/${APP_NAME}"
[ ! -e "${TARGET_DIR}" ] || { echo "Target already exists: ${TARGET_DIR}"; exit 1; }
cp -r "${ROOT}/vps-app/app-template" "${TARGET_DIR}"
[ -f "${TARGET_DIR}/.env.production.example" ] && cp "${TARGET_DIR}/.env.production.example" "${TARGET_DIR}/.env.production"
[ -f "${TARGET_DIR}/.env.staging.example" ] && cp "${TARGET_DIR}/.env.staging.example" "${TARGET_DIR}/.env.staging"
[ -f "${TARGET_DIR}/docker-compose.yml.example" ] && cp "${TARGET_DIR}/docker-compose.yml.example" "${TARGET_DIR}/docker-compose.yml"
echo "App created at: ${TARGET_DIR}"
