# PostgreSQL Database

## Overview

Production-ready PostgreSQL 16 deployment with automatic backups, monitoring, and SSL support.

## Features

- **PostgreSQL 16** with streaming replication support
- **SSL/TLS** encryption for connections
- **Automatic backups** with retention policies
- **Prometheus metrics** via postgres_exporter
- **Health checks** and monitoring
- **Volume snapshots** support

## Quick Start

```bash
cd vps-db/postgres
cp .env.example .env
# Edit .env with your configuration

docker-compose up -d

# Verify
docker exec postgres pg_isready -U postgres
docker exec postgres psql -U postgres -c "SELECT version();"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_VERSION` | 16-alpine | PostgreSQL image version |
| `POSTGRES_DB` | appdb | Default database name |
| `POSTGRES_USER` | postgres | Database user |
| `POSTGRES_PASSWORD` | - | User password (required) |
| `POSTGRES_ROOT_PASSWORD` | - | Root password (required) |
| `POSTGRES_MAX_CONNECTIONS` | 100 | Max client connections |
| `POSTGRES_SHARED_BUFFERS` | 256MB | Shared memory |
| `POSTGRES_MAX_WAL_SIZE` | 1GB | WAL size limit |

### SSL Configuration

```bash
POSTGRES_SSL=-on
POSTGRES_SSL_CERT=/certs/server.crt
POSTGRES_SSL_KEY=/certs/server.key
```

## Replication

### Setup Replication User

```sql
-- On primary
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replication_password';

-- pg_hba.conf
host replication replicator 10.0.0.0/24 md5
```

## Monitoring

### Prometheus Metrics

Access metrics at `postgres:9187/metrics`:

```bash
# Using postgres_exporter
docker exec postgres-exporter wget -O- http://localhost:9187/metrics
```

### Key Metrics

- `pg_stat_database_tup_inserted` - Rows inserted
- `pg_stat_database_tup_updated` - Rows updated
- `pg_stat_database_tup_deleted` - Rows deleted
- `pg_stat_bgwriter_buffers_alloc` - Buffer allocations
- `pg_locks` - Active locks

## Backup

### Manual Backup

```bash
# Full backup
docker exec postgres pg_dump -U postgres -Fc appdb > backup.dump

# SQL backup
docker exec postgres pg_dump -U postgres appdb > backup.sql
```

### Automated Backups

Backups run daily at 02:00 UTC via cron:

```bash
# View backup logs
tail -f backups/backup.log

# List backups
ls -la backups/
```

## Restore

### Restore from Dump

```bash
# Stop application
docker-compose stop app

# Drop and recreate database
docker exec postgres psql -U postgres -c "DROP DATABASE IF EXISTS appdb;"
docker exec postgres psql -U postgres -c "CREATE DATABASE appdb;"

# Restore
docker exec -i postgres pg_restore -U postgres -d appdb < backup.dump

# Start application
docker-compose start app
```

## Extensions

Enable PostgreSQL extensions:

```bash
POSTGRES_EXTENSIONS=pg_trgm,uuid-ossp,postgis
```

Available extensions:
- `pg_trgm` - Trigram matching
- `uuid-ossp` - UUID generation
- `postgis` - Spatial/geographic features
- `pgcrypto` - Cryptographic functions
- `hstore` - Key-value store
