# Backup and Restore Guide

## Overview

This guide covers backup and restore procedures for all databases in the VPS stack.

## Automated Backups

### Setup Cron Job

```bash
# Edit crontab
crontab -e

# Add these lines:
# Daily backup at 2 AM
0 2 * * * cd /path/to/vps-db && ./scripts/backup-all.sh >> logs/backup.log 2>&1

# Weekly cleanup on Sundays at 3 AM
0 3 * * 0 find /path/to/vps-db/backups -name "*.gz" -mtime +30 -delete
```

### Backup Schedule

| Type | Schedule | Retention |
|------|----------|-----------|
| Daily | 02:00 | 7 days |
| Weekly | Sun 03:00 | 4 weeks |
| Monthly | 1st 04:00 | 12 months |

## Manual Backup

### Backup All Databases

```bash
./scripts/backup-all.sh
```

### Backup Individual Database

```bash
# PostgreSQL
cd postgres
docker-compose run --rm backup

# MySQL
cd mysql
docker-compose run --rm backup

# Redis
cd redis
docker-compose run --rm backup
```

### Backup Commands

#### PostgreSQL

```bash
# Full dump with compression
docker exec postgres pg_dump -U postgres -Fc appdb | gzip > backup.dump.gz

# SQL dump
docker exec postgres pg_dump -U postgres appdb > backup.sql

# All databases
docker exec postgres pg_dumpall -U postgres > backup_all.sql
```

#### MySQL

```bash
# Single database
docker exec mysql mysqldump -u root -p'password' appdb | gzip > backup.sql.gz

# All databases
docker exec mysql mysqldump -u root -p'password' --all-databases | gzip > all_databases.sql.gz

# With master data for replication
docker exec mysql mysqldump -u root -p'password' --all-databases --master-data=2 > backup.sql
```

#### Redis

```bash
# Trigger save and copy
docker exec redis redis-cli BGSAVE
docker exec redis cat /data/dump.rdb > backup.rdb

# Copy AOF
docker cp redis:/data/appendonly.aof ./backup.aof
```

## Restore

### Interactive Restore

```bash
./scripts/restore.sh interactive
```

### Restore PostgreSQL

```bash
# From SQL dump
gunzip < backup.sql.gz | docker exec -i postgres psql -U postgres appdb

# From custom dump
docker exec -i postgres pg_restore -U postgres -d appdb < backup.dump

# Restore all databases
docker exec -i postgres psql -U postgres < backup_all.sql
```

### Restore MySQL

```bash
# From SQL dump
gunzip < backup.sql.gz | docker exec -i mysql mysql -u root -p'password'

# To specific database
gunzip < backup.sql.gz | docker exec -i mysql mysql -u root -p'password' appdb
```

### Restore Redis

```bash
# Stop Redis
docker exec redis redis-cli -a 'password' SHUTDOWN SAVE

# Copy backup
docker cp backup.rdb redis:/data/dump.rdb

# Restart Redis
docker restart redis
```

## Point-in-Time Recovery

### PostgreSQL

1. Take base backup
2. Configure WAL archiving
3. Restore to point in time

```bash
# Enable WAL archiving (postgresql.conf)
archive_mode = on
archive_command = 'cp %p /archive/%f'
restore_command = 'cp /archive/%f %p'
```

### MySQL

```bash
# Enable binary logging
log-bin = mysql-bin
expire_logs_days = 7

# Full backup with position
mysqldump -u root -p --all-databases --master-data=2 > backup.sql

# Point in time restore
mysqlbinlog --stop-datetime="2024-01-01 12:00:00" mysql-bin.000001 | mysql -u root -p
```

## Verification

### Verify PostgreSQL Backup

```bash
# Check dump integrity
gunzip < backup.sql.gz | pg_restore --list -

# Test restore to temporary database
docker exec postgres pg_restore -U postgres -d testdb < backup.dump
```

### Verify MySQL Backup

```bash
# Check SQL syntax
gunzip < backup.sql.gz | head -100

# Test import
mysql -u root -p -e "CREATE DATABASE test;"
gunzip < backup.sql.gz | mysql -u root -p test
```

### Verify Redis Backup

```bash
# Check RDB file
file backup.rdb

# Verify with redis-cli
redis-cli -a 'password' --ldb-load yes backup.rdb
```

## Backup Rotation

### Retention Policy

| Age | Keep |
|-----|------|
| < 24 hours | All |
| < 7 days | Daily |
| < 30 days | Weekly |
| < 365 days | Monthly |
| > 365 days | Yearly |

### Cleanup Script

```bash
#!/bin/bash
# Cleanup old backups
find /backups -name "*.gz" -mtime +30 -delete
find /backups -name "*.sha256" -mtime +30 -delete
```

## Off-site Backup

### Copy to S3

```bash
# Install AWS CLI
pip install awscli

# Configure
aws configure

# Copy backups
aws s3 cp backup.sql.gz s3://my-bucket/backups/
```

### Copy to B2

```bash
# Install B2 CLI
pip install b2

# Configure
b2 authorize-account

# Copy
b2 upload-file my-bucket backup.sql.gz backups/
```

## Disaster Recovery

### Full System Restore

1. Provision new server
2. Install Docker
3. Clone repository
4. Restore from backup
5. Verify integrity
6. Update DNS

### RTO/RPO Targets

| Database | RTO | RPO |
|----------|-----|-----|
| PostgreSQL | 30 min | 24 hours |
| MySQL | 30 min | 24 hours |
| Redis | 15 min | 1 hour |
