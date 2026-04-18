#!/usr/bin/env bash
set -euo pipefail
NAME="${1:-}"
ROOT="${ROOT:-/opt/vps}"
[ -n "${NAME}" ] || { echo "Usage: $0 <project-name>"; exit 1; }
"${ROOT}/vps-infra/shared/scripts/create_app.sh" "${NAME}"
echo "Project bootstrap complete for ${NAME}"
