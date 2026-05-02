# VPS Database Stack

Production-ready database infrastructure for VPS deployments with high availability, monitoring, and automated backups.

## Features

- **High Availability**: Automatic failover with replication
- **Connection Pooling**: PgBouncer & ProxySQL integration
- **SSL/TLS**: Encrypted connections
- **Automated Backups**: Scheduled with rotation
- **Monitoring**: Prometheus metrics & health checks
- **Security**: Network policies, secrets management
- **Easy Scaling**: Volume expansion support

## Database Options

### SQL Databases

| Database | Port | SSL | HA | Use Case |
|----------|------|-----|-----|----------|
| [PostgreSQL](postgres/) | 5432 | Yes | [Patroni](postgres/ha/) | Transactional data |
| [MySQL](mysql/) | 3306 | Yes | [Orchestrator](mysql/ha/) | Web applications |
| [MariaDB](mariadb/) | 3306 | Yes | [Galera](mariadb/ha/) | MySQL replacement |
| [SQL Server](sqlserver/) | 1433 | Yes | [AG](sqlserver/ha/) | Enterprise apps |

### NoSQL Databases

| Database | Port | Persistence | Use Case |
|----------|------|-------------|----------|
| [MongoDB](mongodb/) | 27017 | WiredTiger | Document store |
| [Redis](redis/) | 6379 | AOF/RDB | Cache, sessions |
| [InfluxDB](influxdb/) | 8086 | TSM | Time-series |

## Quick Start

### Single Database

```bash
# PostgreSQL
cd vps-db/postgres
cp .env.example .env
docker-compose up -d

# MySQL
cd vps-db/mysql
docker-compose up -d

# Redis
cd vps-db/redis
docker-compose up -d
```

### Full Stack

```bash
cd vps-db
cp .env.example .env
docker-compose -f docker-compose.yml up -d
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Application Layer                       │
├─────────────────────────────────────────────────────────────┤
│    PgBouncer      │     ProxySQL      │    Redis Sentinel   │
│   (Port 5433)    │    (Port 6033)    │    (Port 6379)     │
├─────────────────────────────────────────────────────────────┤
│   PostgreSQL      │      MySQL        │       Redis         │
│   Primary/Replica │  Primary/Replica  │    Master/Slave     │
├─────────────────────────────────────────────────────────────┤
│                    Shared Storage (NFS/Block)               │
└─────────────────────────────────────────────────────────────┘
```

## Connection Strings

```bash
# PostgreSQL (Direct)
postgresql://user:pass@host:5432/dbname

# PostgreSQL (Pooled)
postgresql://user:pass@host:5433/dbname

# MySQL (Direct)
mysql://user:pass@host:3306/dbname

# MySQL (Pooled)
mysql://user:pass@host:6033/dbname

# Redis
redis://host:6379/0
```

## Management

```bash
# Health check all databases
./scripts/health-check.sh

# Backup all databases
./scripts/backup-all.sh

# Restore a database
./scripts/restore.sh --database=postgres --backup=backup.sql.gz

# View logs
docker-compose logs -f postgres
```

## Monitoring

| Endpoint | Metrics |
|----------|---------|
| `postgres:9187` | PostgreSQLExporter |
| `mysql:9104` | MySQLExporter |
| `redis:9121` | RedisExporter |
| `pgbouncer:5432` | PgBouncer stats |

## Security

- [x] SSL/TLS encryption
- [x] Strong passwords required
- [x] Network policies
- [x] Non-root containers
- [x] Read-only root filesystem
- [x] Resource limits

## Backup Schedule

| Type | Frequency | Retention |
|------|-----------|-----------|
| Hourly | :00 | 24 hours |
| Daily | 02:00 | 7 days |
| Weekly | Sun 03:00 | 4 weeks |
| Monthly | 1st 04:00 | 12 months |

## Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [Configuration Reference](docs/CONFIG.md)
- [Backup & Restore](docs/BACKUP.md)
- [Monitoring Setup](docs/MONITORING.md)
- [Security Guide](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
