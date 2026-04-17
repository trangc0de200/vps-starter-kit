#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/opt/vps}"
find "${ROOT}" -maxdepth 4 \( -name "docker-compose.yml" -o -name "docker-compose.yaml" \) | sort
