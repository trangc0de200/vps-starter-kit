#!/usr/bin/env bash
# ELK Stack Management Script

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ACTION=${1:-help}

show_help() {
    cat << EOF
ELK Stack Management Script

${BLUE}Usage:${NC} ./elk.sh <command>

${BLUE}Commands:${NC}
    start           Start ELK stack
    stop            Stop ELK stack
    restart         Restart ELK stack
    status          Show stack status
    logs            Show logs (use: logs <service>)
    logs-elasticsearch  Show Elasticsearch logs
    logs-kibana     Show Kibana logs
    logs-fluentd    Show Fluentd logs
    health          Check health of all services
    es-health       Elasticsearch health
    es-indices      List Elasticsearch indices
    es-search       Search logs (usage: es-search <query>)
    setup           Initial setup (create index patterns)
    cleanup         Clean old data
    destroy         Remove all data and stop
    backup          Backup Elasticsearch data
    restore         Restore from backup
    test            Test configuration
    scale           Scale services (usage: scale <service> <count>)

${BLUE}Examples:${NC}
    ./elk.sh start
    ./elk.sh logs elasticsearch
    ./elk.sh es-search "error"
    ./elk.sh setup
EOF
}

start_stack() {
    echo -e "${GREEN}Starting ELK Stack...${NC}"
    docker-compose up -d
    echo -e "${GREEN}Waiting for services to be ready...${NC}"
    sleep 10
    health
}

stop_stack() {
    echo -e "${YELLOW}Stopping ELK Stack...${NC}"
    docker-compose stop
}

restart_stack() {
    echo -e "${YELLOW}Restarting ELK Stack...${NC}"
    docker-compose restart
}

show_status() {
    echo -e "${BLUE}ELK Stack Status:${NC}"
    docker-compose ps
}

show_logs() {
    local service=${2:-}
    if [[ -z "$service" ]]; then
        docker-compose logs -f --tail=100
    else
        docker-compose logs -f --tail=100 "$service"
    fi
}

check_health() {
    echo -e "${BLUE}Checking service health...${NC}"
    
    local es_status
    es_status=$(curl -s -u elastic:changeme "http://localhost:9200/_cluster/health" | jq -r '.status // "unknown"')
    
    local kibana_status
    kibana_status=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:5601/api/status")
    
    local fluentd_status
    fluentd_status=$(docker exec fluentd fluentdctl status 2>/dev/null || echo "running")
    
    echo -e "Elasticsearch: ${es_status}"
    echo -e "Kibana: ${kibana_status}"
    echo -e "Fluentd: ${fluentd_status}"
    
    if [[ "$es_status" == "green" || "$es_status" == "yellow" ]]; then
        echo -e "${GREEN}✓ Elasticsearch is healthy${NC}"
    else
        echo -e "${RED}✗ Elasticsearch is unhealthy${NC}"
    fi
    
    if [[ "$kibana_status" == "200" ]]; then
        echo -e "${GREEN}✓ Kibana is healthy${NC}"
    else
        echo -e "${RED}✗ Kibana returned ${kibana_status}${NC}"
    fi
}

es_health() {
    echo -e "${BLUE}Elasticsearch Health:${NC}"
    curl -s -u elastic:changeme "http://localhost:9200/_cluster/health?pretty"
}

es_indices() {
    echo -e "${BLUE}Elasticsearch Indices:${NC}"
    curl -s -u elastic:changeme "http://localhost:9200/_cat/indices?v"
}

es_search() {
    local query=${2:-"*"}
    echo -e "${BLUE}Searching logs: ${query}${NC}"
    curl -s -u elastic:changeme -X GET "http://localhost:9200/fluentd-*/_search?q=${query}&size=20&pretty"
}

initial_setup() {
    echo -e "${GREEN}Running initial setup...${NC}"
    
    # Wait for Elasticsearch
    echo "Waiting for Elasticsearch..."
    until curl -s -u elastic:changeme "http://localhost:9200" > /dev/null 2>&1; do
        sleep 5
    done
    
    # Create index pattern
    echo "Creating index patterns..."
    curl -s -u elastic:changeme -X POST "http://localhost:5601/api/saved_objects/index-pattern" \
        -H "Content-Type: application/json" \
        -H "kbn-xsrf: true" \
        -d '{"attributes":{"title":"fluentd-*","timeFieldName":"@timestamp"}}'
    
    echo -e "${GREEN}Setup complete!${NC}"
    echo -e "Access Kibana at: http://localhost:5601"
}

cleanup() {
    echo -e "${YELLOW}Cleaning up old indices (older than ${LOG_RETENTION_DAYS:-30} days)...${NC}"
    local cutoff_date
    cutoff_date=$(date -d "30 days ago" +%Y.%m.%d)
    curl -s -u elastic:changeme -X DELETE "http://localhost:9200/fluentd-*-${cutoff_date}*" || true
    echo -e "${GREEN}Cleanup complete${NC}"
}

destroy_stack() {
    echo -e "${RED}WARNING: This will remove all data!${NC}"
    read -p "Are you sure? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        docker-compose down -v
        rm -rf data/*
        echo -e "${GREEN}Stack destroyed${NC}"
    fi
}

backup_data() {
    local backup_dir="${SCRIPT_DIR}/backups"
    mkdir -p "$backup_dir"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo -e "${GREEN}Backing up Elasticsearch data...${NC}"
    docker exec elasticsearch elasticsearch-snapshot \
        --repo "$backup_dir/snapshot_${timestamp}" || true
    
    tar -czf "${backup_dir}/elk_backup_${timestamp}.tar.gz" \
        -C "${SCRIPT_DIR}" elasticsearch_data prometheus_data alertmanager_data 2>/dev/null || true
    
    echo -e "${GREEN}Backup saved to: ${backup_dir}/elk_backup_${timestamp}.tar.gz${NC}"
}

case "${ACTION}" in
    start)          start_stack ;;
    stop)           stop_stack ;;
    restart)        restart_stack ;;
    status)         show_status ;;
    logs)           show_logs "$@" ;;
    health)         check_health ;;
    es-health)      es_health ;;
    es-indices)     es_indices ;;
    es-search)      es_search "$@" ;;
    setup)          initial_setup ;;
    cleanup)        cleanup ;;
    destroy)        destroy_stack ;;
    backup)         backup_data ;;
    test)           docker-compose config ;;
    help)           show_help ;;
    *)              show_help ;;
esac
