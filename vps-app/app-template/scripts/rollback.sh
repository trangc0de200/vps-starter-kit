#!/usr/bin/env bash
set -euo pipefail
TARGET="$1"
git fetch origin
git checkout "${TARGET}"
docker compose up -d --build
if [ -f ./healthcheck.sh ]; then ./healthcheck.sh production; fi
