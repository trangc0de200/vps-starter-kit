#!/usr/bin/env bash
# Database Connection Pool Management Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
POOL_TYPE=${1:-help}
ACTION=${2:-help}

show_help() {
    cat << EOF
Database Connection Pool Management Script

${BLUE}Usage:${NC} ./pool.sh <pool_type> <command>

${BLUE}Pool Types:${NC}
    pgbouncer    PostgreSQL connection pooler
    proxysql     MySQL/MariaDB proxy

${BLUE}Commands:${NC}
    start        Start the pooler
    stop         Stop the pooler
    restart      Restart the pooler
    status       Show pool status
    stats        Show detailed statistics
    logs         Show logs
    health       Check health
    connect      Connect to database via pooler

${BLUE}Examples:${NC}
    ./pool.sh pgbouncer start
    ./pool.sh proxysql stats
    ./pool.sh pgbouncer connect
EOF
}

# PgBouncer functions
pgbouncer_start() {
    echo -e "${GREEN}Starting PgBouncer...${NC}"
    cd pgbouncer
    docker-compose up -d
    echo -e "${GREEN}PgBouncer started on port 5433${NC}"
}

pgbouncer_stop() {
    echo -e "${YELLOW}Stopping PgBouncer...${NC}"
    cd pgbouncer
    docker-compose down
}

pgbouncer_status() {
    echo -e "${BLUE}PgBouncer Status:${NC}"
    docker exec pgbouncer pgbouncer -V 2>/dev/null || echo "PgBouncer not running"
    echo ""
    docker-compose -f pgbouncer/docker-compose.yml ps
}

pgbouncer_stats() {
    echo -e "${BLUE}PgBouncer Statistics:${NC}"
    docker exec -i pgbouncer psql -h localhost -p 5432 -U pgbouncer -c "SHOW POOLS" 2>/dev/null || echo "Cannot connect to PgBouncer"
    echo ""
    docker exec -i pgbouncer psql -h localhost -p 5432 -U pgbouncer -c "SHOW STATS" 2>/dev/null || true
}

pgbouncer_health() {
    echo -e "${BLUE}PgBouncer Health Check:${NC}"
    if docker exec pgbouncer sh -c "echo 'SHOW VERSION;' | nc localhost 5432" &>/dev/null; then
        echo -e "${GREEN}✓ PgBouncer is responding${NC}"
    else
        echo -e "${RED}✗ PgBouncer is not responding${NC}"
    fi
}

pgbouncer_connect() {
    echo -e "${BLUE}Connecting to PostgreSQL via PgBouncer...${NC}"
    docker exec -it pgbouncer psql -h localhost -p 5432 -U postgres
}

# ProxySQL functions
proxysql_start() {
    echo -e "${GREEN}Starting ProxySQL...${NC}"
    cd proxysql
    docker-compose up -d
    echo -e "${GREEN}ProxySQL started:${NC}"
    echo "  - Admin: localhost:6032"
    echo "  - MySQL: localhost:6033"
}

proxysql_stop() {
    echo -e "${YELLOW}Stopping ProxySQL...${NC}"
    cd proxysql
    docker-compose down
}

proxysql_status() {
    echo -e "${BLUE}ProxySQL Status:${NC}"
    docker exec proxysql proxysql --version 2>/dev/null || echo "ProxySQL not running"
    echo ""
    docker-compose -f proxysql/docker-compose.yml ps
}

proxysql_stats() {
    echo -e "${BLUE}ProxySQL Statistics:${NC}"
    docker exec -i proxysql mysql -h 127.0.0.1 -P 6032 -u admin -padmin -e "
        SELECT * FROM stats_mysql_connection_pool;
    " 2>/dev/null || echo "Cannot connect to ProxySQL"
    echo ""
    echo "Query Statistics:"
    docker exec -i proxysql mysql -h 127.0.0.1 -P 6032 -u admin -padmin -e "
        SELECT * FROM stats_mysql_queries;
    " 2>/dev/null || true
}

proxysql_health() {
    echo -e "${BLUE}ProxySQL Health Check:${NC}"
    if docker exec proxysql mysqladmin ping -h 127.0.0.1 -P 6032 -u admin -padmin --silent 2>/dev/null; then
        echo -e "${GREEN}✓ ProxySQL is responding${NC}"
    else
        echo -e "${RED}✗ ProxySQL is not responding${NC}"
    fi
}

proxysql_connect() {
    echo -e "${BLUE}Connecting to MySQL via ProxySQL...${NC}"
    docker exec -it proxysql mysql -h 127.0.0.1 -P 6033 -u root -pchangeme
}

# Execute commands
case "${POOL_TYPE}" in
    pgbouncer)
        case "${ACTION}" in
            start)    pgbouncer_start ;;
            stop)     pgbouncer_stop ;;
            restart)  pgbouncer_stop; pgbouncer_start ;;
            status)   pgbouncer_status ;;
            stats)    pgbouncer_stats ;;
            health)   pgbouncer_health ;;
            connect)  pgbouncer_connect ;;
            logs)     docker-compose -f pgbouncer/docker-compose.yml logs -f ;;
            *)        show_help ;;
        esac
        ;;
    proxysql)
        case "${ACTION}" in
            start)    proxysql_start ;;
            stop)     proxysql_stop ;;
            restart)  proxysql_stop; proxysql_start ;;
            status)   proxysql_status ;;
            stats)    proxysql_stats ;;
            health)   proxysql_health ;;
            connect)  proxysql_connect ;;
            logs)     docker-compose -f proxysql/docker-compose.yml logs -f ;;
            *)        show_help ;;
        esac
        ;;
    both)
        case "${ACTION}" in
            start)
                pgbouncer_start
                proxysql_start
                ;;
            stop)
                pgbouncer_stop
                proxysql_stop
                ;;
            restart)
                pgbouncer_stop; pgbouncer_start
                proxysql_stop; proxysql_start
                ;;
            status)
                pgbouncer_status
                proxysql_status
                ;;
            *)
                show_help
                ;;
        esac
        ;;
    help)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown pool type: ${POOL_TYPE}${NC}"
        show_help
        exit 1
        ;;
esac
