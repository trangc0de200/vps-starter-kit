#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-/opt/vps/backups}"

echo "Checking backup files under ${ROOT} ..."
find "${ROOT}" -type f \( -name "*.sql.gz" -o -name "*.bak" -o -name "*.rdb" -o -name "*.dump" \) -printf "%TY-%Tm-%Td %TT %p %k KB\n" | sort
