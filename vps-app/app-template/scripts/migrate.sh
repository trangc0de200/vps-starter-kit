#!/usr/bin/env bash
# Database Migration Script
# Run database migrations

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
    cat << EOF
Migration Script

Usage: $0 [COMMAND]

Commands:
    up        Run migrations
    down      Rollback last migration
    status    Show migration status
    create    Create new migration

Examples:
    $0 up
    $0 down
    $0 status
    $0 create add_users_table
EOF
    exit 1
}

COMMAND="${1:-}"
[[ -z "$COMMAND" ]] && usage

case "$COMMAND" in
    up)
        echo "Running migrations..."
        if docker-compose exec -T app npm run migrate:up 2>/dev/null; then
            echo "Migrations complete"
        elif docker-compose exec -T app python manage.py migrate 2>/dev/null; then
            echo "Migrations complete"
        elif docker-compose exec -T app php artisan migrate 2>/dev/null; then
            echo "Migrations complete"
        else
            echo "No migration command found"
            exit 1
        fi
        ;;
    
    down)
        echo "Rolling back..."
        if docker-compose exec -T app npm run migrate:down 2>/dev/null; then
            echo "Rollback complete"
        elif docker-compose exec -T app python manage.py migrate zero 2>/dev/null; then
            echo "Rollback complete"
        elif docker-compose exec -T app php artisan migrate:rollback 2>/dev/null; then
            echo "Rollback complete"
        else
            echo "No rollback command found"
            exit 1
        fi
        ;;
    
    status)
        echo "Migration status..."
        if docker-compose exec -T app npm run migrate:status 2>/dev/null; then
            :
        elif docker-compose exec -T app python manage.py showmigrations 2>/dev/null; then
            :
        elif docker-compose exec -T app php artisan migrate:status 2>/dev/null; then
            :
        else
            echo "No status command found"
            exit 1
        fi
        ;;
    
    create)
        NAME="${2:-}"
        [[ -z "$NAME" ]] && echo "Usage: $0 create <migration_name>" && exit 1
        
        TIMESTAMP=$(date +%Y%m%d%H%M%S)
        echo "Creating migration: ${TIMESTAMP}_${NAME}"
        
        mkdir -p "${APP_DIR}/migrations"
        touch "${APP_DIR}/migrations/${TIMESTAMP}_${NAME}.up.sql"
        touch "${APP_DIR}/migrations/${TIMESTAMP}_${NAME}.down.sql"
        
        echo "Created:"
        echo "  ${APP_DIR}/migrations/${TIMESTAMP}_${NAME}.up.sql"
        echo "  ${APP_DIR}/migrations/${TIMESTAMP}_${NAME}.down.sql"
        ;;
    
    *)
        usage
        ;;
esac
