# Configuration Reference

## Environment Variables

### PostgreSQL

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_VERSION` | 16-alpine | Docker image |
| `POSTGRES_CONTAINER_NAME` | postgres | Container name |
| `POSTGRES_PORT` | 5432 | Exposed port |
| `POSTGRES_DB` | appdb | Default database |
| `POSTGRES_USER` | postgres | Database user |
| `POSTGRES_PASSWORD` | - | User password |
| `POSTGRES_EXPORTER_PORT` | 9187 | Prometheus exporter port |

### MySQL

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_VERSION` | 8.0 | Docker image |
| `MYSQL_CONTAINER_NAME` | mysql | Container name |
| `MYSQL_PORT` | 3306 | Exposed port |
| `MYSQL_DATABASE` | appdb | Default database |
| `MYSQL_USER` | mysql | Database user |
| `MYSQL_PASSWORD` | - | User password |
| `MYSQL_ROOT_PASSWORD` | - | Root password |
| `MYSQL_EXPORTER_PORT` | 9104 | Prometheus exporter port |

### Redis

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_VERSION` | 7.2-alpine | Docker image |
| `REDIS_CONTAINER_NAME` | redis | Container name |
| `REDIS_PORT` | 6379 | Exposed port |
| `REDIS_PASSWORD` | - | Redis password |
| `REDIS_MAXMEMORY` | 256mb | Max memory |
| `REDIS_MAXMEMORY_POLICY` | allkeys-lru | Eviction policy |
| `REDIS_EXPORTER_PORT` | 9121 | Prometheus exporter port |

### Connection Pooling

| Variable | Default | Description |
|----------|---------|-------------|
| `PGBOUNCER_PORT` | 5433 | PgBouncer port |
| `PROXYSQL_PORT` | 6033 | ProxySQL client port |
| `PROXYSQL_ADMIN_PORT` | 6032 | ProxySQL admin port |

### Backup

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_ENABLED` | true | Enable backups |
| `BACKUP_SCHEDULE` | 0 2 * * * | Cron schedule |
| `BACKUP_RETENTION_DAYS` | 30 | Retention period |

### Network

| Variable | Default | Description |
|----------|---------|-------------|
| `NETWORK_NAME` | db_network | Docker network |
| `NETWORK_SUBNET` | 172.28.0.0/16 | Network subnet |

## PostgreSQL Performance Tuning

### Shared Buffers

```bash
POSTGRES_SHARED_BUFFERS=256MB  # 25% of RAM
```

### Work Memory

```bash
POSTGRES_WORK_MEM=4MB  # For complex queries
```

### Maintenance Work Memory

```bash
POSTGRES_MAINTENANCE_WORK_MEM=64MB  # For VACUUM, CREATE INDEX
```

### Checkpoint Settings

```bash
POSTGRES_CHECKPOINT_COMPLETION_TARGET=0.9
POSTGRES_WAL_BUFFERS=16MB
```

### Query Planner

```bash
POSTGRES_RANDOM_PAGE_COST=1.1  # For SSD
POSTGRES_EFFECTIVE_IO_CONCURRENCY=200
```

## MySQL Performance Tuning

### InnoDB Buffer Pool

```bash
MYSQL_INNODB_BUFFER_POOL_SIZE=1G  # 70% of RAM
```

### Connection Settings

```bash
MYSQL_MAX_CONNECTIONS=200
```

### Logging

```bash
MYSQL_SLOW_QUERY_LOG=1
MYSQL_LONG_QUERY_TIME=2
```

## Redis Memory Management

### Max Memory

```bash
REDIS_MAXMEMORY=1gb
```

### Eviction Policy

| Policy | Description |
|--------|-------------|
| `noeviction` | Reject writes |
| `allkeys-lru` | Evict LRU keys |
| `allkeys-lfu` | Evict LFU keys |
| `volatile-lru` | Evict LRU with TTL |
| `volatile-random` | Evict random with TTL |

### Persistence

```bash
REDIS_SAVE="900 1 300 10 60 10000"
REDIS_APPENDONLY=yes
REDIS_APPENDFSYNC=everysec
```

## SSL/TLS Configuration

### PostgreSQL SSL

```bash
POSTGRES_SSL=on
POSTGRES_SSL_CERT_FILE=/var/lib/postgresql/data/server.crt
POSTGRES_SSL_KEY_FILE=/var/lib/postgresql/data/server.key
```

### MySQL SSL

MySQL 8.0+ enables SSL automatically. To enforce:

```sql
-- Require SSL for user
ALTER USER 'user'@'%' REQUIRE SSL;
```

## Docker Resource Limits

### PostgreSQL

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
    reservations:
      cpus: '0.5'
      memory: 1G
```

### MySQL

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
```

### Redis

```yaml
deploy:
  resources:
    limits:
      cpus: '1'
      memory: 1G
```

## Connection Strings

### PostgreSQL

```bash
# Direct
postgresql://user:pass@host:5432/dbname

# With SSL
postgresql://user:pass@host:5432/dbname?sslmode=require

# Pooled (PgBouncer)
postgresql://user:pass@host:5433/dbname
```

### MySQL

```bash
# Direct
mysql://user:pass@host:3306/dbname

# Pooled (ProxySQL)
mysql://user:pass@host:6033/dbname
```

### Redis

```bash
redis://user:pass@host:6379/0
redis://user:pass@host:6379/0#mydb
```
