#!/usr/bin/env bash
set -euo pipefail
LEN="${1:-32}"
tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom | head -c "${LEN}" ; echo
