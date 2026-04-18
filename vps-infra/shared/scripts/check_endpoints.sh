#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <url1> [url2] [url3] ..."
  exit 1
fi

for url in "$@"; do
  echo "Checking ${url}"
  if curl -fsS "${url}" >/dev/null; then
    echo "OK: ${url}"
  else
    echo "FAIL: ${url}"
  fi
done
