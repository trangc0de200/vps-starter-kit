#!/usr/bin/env bash
set -euo pipefail
docker image prune -f
docker builder prune -f
