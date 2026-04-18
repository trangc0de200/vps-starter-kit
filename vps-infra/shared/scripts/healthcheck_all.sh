#!/usr/bin/env bash
set -euo pipefail
echo "Docker containers:"
docker ps
echo
echo "Disk usage:"
df -h
echo
echo "Docker networks:"
docker network ls
