#!/usr/bin/env bash
set -euo pipefail

echo "Hostname:"
hostname

echo
echo "Uptime:"
uptime

echo
echo "Memory:"
free -h

echo
echo "Disk:"
df -h

echo
echo "Docker:"
docker --version
docker compose version
