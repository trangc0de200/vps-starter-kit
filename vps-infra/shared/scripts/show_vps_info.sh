#!/usr/bin/env bash
set -euo pipefail
hostname
echo
uptime
echo
free -h
echo
df -h
echo
docker --version
docker compose version
