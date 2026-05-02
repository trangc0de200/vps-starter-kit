# Deployment Guide

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB RAM
- 20GB disk space

## Quick Start

### 1. Clone and Configure

```bash
cd vps-db
cp .env.example .env

# Edit .env with your passwords
nano .env
```

### 2. Start Databases

```bash
# Start all databases
docker-compose up -d

# Start with monitoring
docker-compose --profile monitoring up -d

# Start with connection pooling
docker-compose --profile pooling up -d
```

### 3. Verify

```bash
# Check status
docker-compose ps

# Run health check
./scripts/health-check.sh

# Connect to database
docker exec -it postgres psql -U postgres
```

## Deployment Options

### Single Database

```bash
# PostgreSQL only
cd postgres && docker-compose up -d

# MySQL only
cd mysql && docker-compose up -d

# Redis only
cd redis && docker-compose up -d
```

### With Connection Pooling

```bash
docker-compose --profile pooling up -d
```

### With Monitoring

```bash
docker-compose --profile monitoring up -d
```

## Configuration

### PostgreSQL

See [PostgreSQL README](postgres/README.md)

### MySQL

See [MySQL README](mysql/README.md)

### Redis

See [Redis README](redis/README.md)

## Backup

### Automated Backup

Add to crontab:

```bash
# Edit crontab
crontab -e

# Add backup job (daily at 2 AM)
0 2 * * * cd /path/to/vps-db && ./scripts/backup-all.sh >> logs/backup.log 2>&1
```

### Manual Backup

```bash
# Backup all databases
./scripts/backup-all.sh

# Backup specific database
cd postgres && docker-compose run --rm backup
```

## Restore

```bash
# Interactive restore
./scripts/restore.sh interactive

# Restore specific backup
./scripts/restore.sh postgres backups/postgres/backup.sql.gz
```

## Monitoring

### Prometheus Metrics

| Database | Port | Endpoint |
|----------|------|----------|
| PostgreSQL | 9187 | /metrics |
| MySQL | 9104 | /metrics |
| Redis | 9121 | /metrics |

### Grafana Dashboard

Import dashboards from `docs/grafana/`

## Networking

Default network: `172.28.0.0/16`

To customize:

```bash
# In .env
NETWORK_SUBNET=10.0.10.0/16
```

## Troubleshooting

### Container won't start

```bash
# Check logs
docker-compose logs postgres
docker-compose logs mysql
docker-compose logs redis

# Check disk space
df -h

# Check memory
free -h
```

### Connection refused

```bash
# Check if container is running
docker ps

# Check port binding
netstat -tlnp | grep 5432
```

### Performance issues

```bash
# Check resource usage
docker stats

# Increase resources in docker-compose
# Edit deploy.resources.limits
```

## Security

- Change default passwords in `.env`
- Use SSL/TLS for connections
- Enable firewall rules
- Restrict network access
- Regular backups

## Maintenance

### Update Images

```bash
# Pull latest images
docker-compose pull

# Restart services
docker-compose up -d
```

### Clean Up

```bash
# Remove unused containers
docker-compose rm

# Remove unused volumes (careful!)
docker volume prune
```
