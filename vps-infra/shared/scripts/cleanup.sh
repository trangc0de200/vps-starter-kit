#!/usr/bin/env bash
set -euo pipefail

echo "Pruning dangling Docker images..."
docker image prune -f

echo "Pruning unused build cache..."
docker builder prune -f

echo "Done."
