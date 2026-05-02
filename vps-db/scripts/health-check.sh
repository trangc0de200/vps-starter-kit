#!/usr/bin/env bash
# Database Health Check Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default credentials (override in .env)
export PGPASSWORD="${POSTGRES_PASSWORD:-change_me_strong_password}"
export MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-change_me_root_password}"
export REDIS_PASSWORD="${REDIS_PASSWORD:-change_me_strong_password}"

log() {
    local status=$1
    local message=$2
    local color=$3
    
    if [[ "$status" == "OK" ]]; then
        echo -e "[${GREEN}OK${NC}] ${message}"
    elif [[ "$status" == "FAIL" ]]; then
        echo -e "[${RED}FAIL${NC}] ${message}"
    elif [[ "$status" == "WARN" ]]; then
        echo -e "[${YELLOW}WARN${NC}] ${message}"
    else
        echo -e "${color}${message}${NC}"
    fi
}

header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
}

check_postgres() {
    header "PostgreSQL Health Check"
    
    # Check if container is running
    if docker ps | grep -q postgres; then
        log "OK" "Container is running"
    else
        log "FAIL" "Container is not running"
        return 1
    fi
    
    # Check connection
    if docker exec postgres pg_isready -U postgres > /dev/null 2>&1; then
        log "OK" "PostgreSQL is accepting connections"
    else
        log "FAIL" "PostgreSQL is not accepting connections"
        return 1
    fi
    
    # Get version
    local version=$(docker exec postgres psql -U postgres -t -c "SELECT version();" 2>/dev/null | xargs)
    log "OK" "Version: ${version}"
    
    # Check databases
    local db_count=$(docker exec postgres psql -U postgres -t -c "SELECT count(datname) FROM pg_database WHERE datistemplate = false;" 2>/dev/null | xargs)
    log "OK" "Databases: ${db_count}"
    
    # Check connections
    local conn_count=$(docker exec postgres psql -U postgres -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null | xargs)
    log "OK" "Active connections: ${conn_count}"
    
    # Check replication if configured
    if docker exec postgres psql -U postgres -c "SELECT 1 FROM pg_stat_replication LIMIT 1;" > /dev/null 2>&1; then
        local repl_count=$(docker exec postgres psql -U postgres -t -c "SELECT count(*) FROM pg_stat_replication;" 2>/dev/null | xargs)
        log "OK" "Replication status: ${repl_count} replica(s) connected"
    fi
    
    # Check disk usage
    local disk_usage=$(docker exec postgres psql -U postgres -t -c "SELECT pg_database_size('postgres') / 1024 / 1024;" 2>/dev/null | xargs)
    log "OK" "Database size: ${disk_usage} MB"
    
    # Check exporter
    if curl -sf http://localhost:9187/metrics > /dev/null 2>&1; then
        log "OK" "Prometheus exporter: Running"
    else
        log "WARN" "Prometheus exporter: Not running (monitoring profile)"
    fi
    
    return 0
}

check_mysql() {
    header "MySQL Health Check"
    
    # Check if container is running
    if docker ps | grep -q mysql; then
        log "OK" "Container is running"
    else
        log "FAIL" "Container is not running"
        return 1
    fi
    
    # Check connection
    if docker exec mysql mysqladmin ping -u root -p"${MYSQL_ROOT_PASSWORD}" --silent > /dev/null 2>&1; then
        log "OK" "MySQL is accepting connections"
    else
        log "FAIL" "MySQL is not accepting connections"
        return 1
    fi
    
    # Get version
    local version=$(docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -t -e "SELECT VERSION();" 2>/dev/null | tail -1 | xargs)
    log "OK" "Version: ${version}"
    
    # Check databases
    local db_count=$(docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -t -e "SHOW DATABASES;" 2>/dev/null | grep -v Database | grep -v information_schema | grep -v mysql | grep -v performance_schema | wc -l)
    log "OK" "Databases: ${db_count}"
    
    # Check connections
    local conn_count=$(docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -t -e "SHOW STATUS LIKE 'Threads_connected';" 2>/dev/null | tail -1 | awk '{print $2}')
    log "OK" "Active connections: ${conn_count}"
    
    # Check queries per second
    local qps=$(docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -t -e "SHOW GLOBAL STATUS LIKE 'Questions';" 2>/dev/null | tail -1 | awk '{print $2}')
    log "OK" "Total queries: ${qps}"
    
    # Check InnoDB buffer pool
    local buffer_pool=$(docker exec mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -t -e "SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_pages_free';" 2>/dev/null | tail -1 | awk '{print $2}')
    log "OK" "InnoDB buffer pool pages free: ${buffer_pool}"
    
    # Check exporter
    if curl -sf http://localhost:9104/metrics > /dev/null 2>&1; then
        log "OK" "Prometheus exporter: Running"
    else
        log "WARN" "Prometheus exporter: Not running (monitoring profile)"
    fi
    
    return 0
}

check_redis() {
    header "Redis Health Check"
    
    # Check if container is running
    if docker ps | grep -q redis; then
        log "OK" "Container is running"
    else
        log "FAIL" "Container is not running"
        return 1
    fi
    
    # Check connection
    if docker exec redis redis-cli -a "${REDIS_PASSWORD}" ping > /dev/null 2>&1; then
        log "OK" "Redis is accepting connections"
    else
        log "FAIL" "Redis is not accepting connections"
        return 1
    fi
    
    # Get version
    local version=$(docker exec redis redis-cli -a "${REDIS_PASSWORD}" info server 2>/dev/null | grep "redis_version" | cut -d: -f2 | xargs)
    log "OK" "Version: ${version}"
    
    # Check memory usage
    local memory=$(docker exec redis redis-cli -a "${REDIS_PASSWORD}" info memory 2>/dev/null | grep "used_memory_human" | cut -d: -f2 | xargs)
    log "OK" "Memory used: ${memory}"
    
    # Check keys
    local keys=$(docker exec redis redis-cli -a "${REDIS_PASSWORD}" dbsize 2>/dev/null | xargs)
    log "OK" "Keys in DB: ${keys}"
    
    # Check connected clients
    local clients=$(docker exec redis redis-cli -a "${REDIS_PASSWORD}" info clients 2>/dev/null | grep "connected_clients" | cut -d: -f2 | xargs)
    log "OK" "Connected clients: ${clients}"
    
    # Check hit rate
    local hit_rate=$(docker exec redis redis-cli -a "${REDIS_PASSWORD}" info stats 2>/dev/null | grep "keyspace_hits" -A 1 | tail -1 | awk -F'[=,]' '{if($2+$4>0) printf "%.2f%%", $2/($2+$4)*100}')
    log "OK" "Hit rate: ${hit_rate:-N/A}"
    
    # Check persistence
    local aof=$(docker exec redis redis-cli -a "${REDIS_PASSWORD}" info persistence 2>/dev/null | grep "aof_enabled" | cut -d: -f2 | xargs)
    if [[ "$aof" == "1" ]]; then
        log "OK" "AOF persistence: Enabled"
    else
        log "WARN" "AOF persistence: Disabled"
    fi
    
    # Check exporter
    if curl -sf http://localhost:9121/metrics > /dev/null 2>&1; then
        log "OK" "Prometheus exporter: Running"
    else
        log "WARN" "Prometheus exporter: Not running (monitoring profile)"
    fi
    
    return 0
}

show_summary() {
    header "Summary"
    
    echo "All checks completed. Review results above."
    echo ""
    echo "Next steps:"
    echo "  - View logs: docker-compose logs -f"
    echo "  - Check metrics: curl localhost:9187/metrics (postgres)"
    echo "  - Connect to DB: docker exec -it postgres psql -U postgres"
}

# Main
case "${1:-all}" in
    postgres)
        check_postgres
        ;;
    mysql)
        check_mysql
        ;;
    redis)
        check_redis
        ;;
    all)
        check_postgres || true
        check_mysql || true
        check_redis || true
        show_summary
        ;;
    *)
        echo "Usage: $0 [postgres|mysql|redis|all]"
        exit 1
        ;;
esac
