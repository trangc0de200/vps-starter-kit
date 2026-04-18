#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <hostname1> [hostname2] ..."
  exit 1
fi

for host in "$@"; do
  echo "Checking SSL certificate for ${host}"
  echo | openssl s_client -servername "${host}" -connect "${host}:443" 2>/dev/null | openssl x509 -noout -dates || true
done
