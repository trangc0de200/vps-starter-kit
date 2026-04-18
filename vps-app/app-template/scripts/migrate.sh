#!/usr/bin/env bash
set -euo pipefail
TARGET_ENV="${1:-production}"
echo "Customize migrate.sh for your stack and target environment: ${TARGET_ENV}"
echo "Examples:"
echo "  Laravel  -> docker compose exec -T app php artisan migrate --force"
echo "  Django   -> docker compose exec -T app python manage.py migrate"
echo "  FastAPI  -> docker compose exec -T app alembic upgrade head"
echo "  NestJS   -> docker compose exec -T app npm run migration:run"
