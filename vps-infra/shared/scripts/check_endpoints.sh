#!/usr/bin/env bash
set -euo pipefail
[ "$#" -gt 0 ] || { echo "Usage: $0 <url1> [url2]"; exit 1; }
for url in "$@"; do if curl -fsS "${url}" >/dev/null; then echo "OK: ${url}"; else echo "FAIL: ${url}"; fi; done
