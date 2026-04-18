#!/usr/bin/env bash
set -euo pipefail
docker ps
echo
df -h
echo
docker network ls
