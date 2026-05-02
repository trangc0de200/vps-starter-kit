# MySQL Database

## Overview

Production-ready MySQL 8.0 deployment with automatic backups, monitoring, and SSL support.

## Features

- **MySQL 8.0** with performance schema
- **SSL/TLS** encryption for connections
- **Automatic backups** with retention policies
- **Prometheus metrics** via mysqld_exporter
- **Health checks** and monitoring
- **Slow query log** analysis

## Quick Start

```bash
cd vps-db/mysql
cp .env.example .env
# Edit .env with your configuration

docker-compose up -d

# Verify
docker exec mysql mysqladmin ping -u root -p
docker exec mysql mysql -u root -p -e "SELECT VERSION();"
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_VERSION` | 8.0 | MySQL image version |
| `MYSQL_DATABASE` | appdb | Default database name |
| `MYSQL_USER` | mysql | Database user |
| `MYSQL_PASSWORD` | - | User password (required) |
| `MYSQL_ROOT_PASSWORD` | - | Root password (required) |
| `MYSQL_MAX_CONNECTIONS` | 200 | Max client connections |
| `MYSQL_INNODB_BUFFER_POOL_SIZE` | 256M | InnoDB buffer pool |

### Key MySQL Variables

```bash
# Performance
MYSQL_INNODB_BUFFER_POOL_SIZE=1G
MYSQL_INNODB_LOG_FILE_SIZE=256M
MYSQL_MAX_CONNECTIONS=300

# Logging
MYSQL_SLOW_QUERY_LOG=1
MYSQL_LONG_QUERY_TIME=2
```

## SSL/TLS

MySQL 8.0 uses automatic SSL for connections.

```bash
# Check SSL status
docker exec mysql mysql -u root -p -e "SHOW VARIABLES LIKE '%ssl%';"
```

## Replication

### Setup Replication User

```sql
-- On primary
CREATE USER 'replica'@'%' IDENTIFIED WITH mysql_native_password BY 'replica_password';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
FLUSH PRIVILEGES;
```

### Get Binary Log Position

```sql
SHOW MASTER STATUS;
-- Note: File and Position values
```

## Monitoring

### Prometheus Metrics

Access metrics at `mysql:9104/metrics`:

```bash
docker exec mysql wget -O- http://localhost:9104/metrics
```

### Key Metrics

- `mysql_global_status_bytes_received` - Network received
- `mysql_global_status_bytes_sent` - Network sent
- `mysql_global_status_commands_total` - Commands executed
- `mysql_global_status_innodb_buffer_pool_pages` - Buffer pool pages
- `mysql_global_status_threads_connected` - Active connections

### Slow Query Log

```bash
# Enable slow query log
docker exec mysql mysql -u root -p -e "SET GLOBAL slow_query_log = 'ON';"
docker exec mysql mysql -u root -p -e "SET GLOBAL long_query_time = 2;"

# View slow queries
docker exec mysql cat /var/lib/mysql/mysql-slow.log
```

## Backup

### Manual Backup

```bash
# Full backup with locks
docker exec mysql mysqldump -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  appdb > backup.sql

# Compressed backup
docker exec mysql mysqldump -u root -p appdb | gzip > backup.sql.gz
```

### Point-in-Time Recovery

```bash
# Full backup
docker exec mysql mysqldump -u root -p --all-databases --master-data=2 > full_backup.sql

# Binary logs for point-in-time recovery
docker exec mysql mysqladmin -u root -p flush-logs
```

## Restore

```bash
# Stop application
docker-compose stop app

# Restore database
gunzip < backup.sql.gz | docker exec -i mysql mysql -u root -p

# Or
docker exec -i mysql mysql -u root -p appdb < backup.sql
```

## Users and Permissions

### Create Application User

```sql
-- Create user with specific privileges
CREATE USER 'appuser'@'%' IDENTIFIED BY 'strong_password';
GRANT SELECT, INSERT, UPDATE, DELETE ON appdb.* TO 'appuser'@'%';
FLUSH PRIVILEGES;
```

### Grant Read Replica Access

```sql
-- For read-only operations
CREATE USER 'reader'@'%' IDENTIFIED BY 'reader_password';
GRANT SELECT ON appdb.* TO 'reader'@'%';
FLUSH PRIVILEGES;
```
