# Restore Guide

Complete guide for restoring backups from VPS Backup system.

## Overview

This guide covers restoring:
- PostgreSQL databases
- MySQL databases
- File backups
- Docker volumes
- Encrypted backups

## Quick Restore

### Interactive Mode

```bash
./restore.sh interactive
```

This will guide you through:
1. Select backup type
2. Choose backup file
3. Configure restore options
4. Execute restore

### Command Line

```bash
# PostgreSQL
./restore.sh postgres --file backups/postgres_20240115_120000.sql.gz

# MySQL
./restore.sh mysql --file backups/mysql_20240115_120000.sql.gz

# Files
./restore.sh files --file backups/files_weekly_20240115.tar.gz

# Docker Volume
./restore.sh volume --file backups/docker_volumes_20240115.tar.gz --volume mydata
```

## Restore PostgreSQL

### From SQL dump

```bash
# Basic restore
./restore.sh postgres --file postgres_20240115.sql.gz

# To different database
./restore.sh postgres --file postgres_20240115.sql.gz --database newdb

# From custom format dump
./restore.sh postgres --file postgres_20240115.dump --format custom
```

### Manual Restore

```bash
# Decompress if needed
gunzip postgres_20240115.sql.gz

# Restore to database
cat postgres_20240115.sql | docker exec -i postgres psql -U postgres appdb

# Or use pg_restore for custom format
docker exec -i postgres pg_restore -U postgres -d appdb < postgres_20240115.dump
```

### Point-in-Time Recovery

```bash
# 1. Take base backup
docker exec postgres pg_basebackup -U postgres -D /backups/base -Ft

# 2. Get WAL files
# Configure WAL archiving to S3

# 3. Restore
./restore.sh postgres --pitr --time "2024-01-15 14:30:00"
```

## Restore MySQL

### From SQL dump

```bash
# Basic restore
./restore.sh mysql --file mysql_20240115.sql.gz

# To different database
./restore.sh mysql --file mysql_20240115.sql.gz --database newdb

# Skip create database
./restore.sh mysql --file mysql_20240115.sql.gz --no-create-db
```

### Manual Restore

```bash
# Decompress
gunzip mysql_20240115.sql.gz

# Restore database
cat mysql_20240115.sql | docker exec -i mysql mysql -u root -p'password' appdb

# Or with source
docker exec -i mysql mysql -u root -p'password' appdb < mysql_20240115.sql
```

### With Point-in-Time

```bash
# Enable binary logging
# In my.cnf
log-bin=mysql-bin
expire_logs_days=7

# Full backup with position
./backup.sh run --mysql

# Point in time restore
mysqlbinlog --stop-datetime="2024-01-15 14:30:00" mysql-bin.000001 | mysql -u root -p
```

## Restore Files

### Full Restore

```bash
# Restore all files
./restore.sh files --file files_weekly_20240115.tar.gz

# Restore to custom location
./restore.sh files --file files_weekly_20240115.tar.gz --target /tmp/restore
```

### Partial Restore

```bash
# Extract specific directory
tar -xzf files_weekly_20240115.tar.gz -C /tmp/restore var/www/html
```

### Restore Permissions

```bash
# Preserve permissions
tar --same-owner -xzf files_weekly_20240115.tar.gz -C /

# Or
tar --preserve-permissions -xzf files_weekly_20240115.tar.gz -C /
```

## Restore Docker Volumes

### List Volumes

```bash
docker volume ls
```

### Restore Volume

```bash
# Restore specific volume
./restore.sh volume --file docker_volumes_20240115.tar.gz --volume mydata

# Overwrite existing (creates backup first)
./restore.sh volume --file docker_volumes_20240115.tar.gz --volume mydata --force

# Restore all volumes
./restore.sh volume --file docker_volumes_20240115.tar.gz --all
```

### Manual Volume Restore

```bash
# 1. Stop container
docker-compose stop app

# 2. Backup current volume
docker run --rm -v mydata:/data -v $(pwd):/backup alpine tar czf /backup/mydata_backup.tar.gz -C /data .

# 3. Clear volume
docker volume rm mydata
docker volume create mydata

# 4. Restore
docker run --rm -v mydata:/data -v $(pwd):/backup alpine tar xzf /backup/docker_volumes_20240115.tar.gz

# 5. Restart container
docker-compose start app
```

## Encrypted Backups

### Restore Encrypted Backup

```bash
# Decrypt first
openssl enc -aes-256-cbc -d -pbkdf2 \
    -in files_encrypted.tar.gz.enc \
    -out files.tar.gz \
    -pass pass:your_password

# Then restore
./restore.sh files --file files.tar.gz
```

### Verify Before Restore

```bash
# Check checksum
sha256sum -c backup.tar.gz.sha256

# List contents without extracting
tar -tzf backup.tar.gz | head -20
```

## Cross-Environment Restore

### Restore to Different Server

```bash
# 1. Download backup
aws s3 cp s3://bucket/backups/postgres_20240115.sql.gz ./

# 2. Transfer to new server
scp postgres_20240115.sql.gz user@newserver:/backups/

# 3. Restore
./restore.sh postgres --file /backups/postgres_20240115.sql.gz
```

### Restore Different Version

```bash
# For PostgreSQL version mismatch
docker exec -i postgres psql -U postgres -c "SELECT version();"

# May need pg_dump/pg_restore compatibility
pg_restore -h localhost -U postgres -d appdb -v backup.dump
```

## Pre-Restore Checklist

- [ ] Verify backup file exists and is not corrupted
- [ ] Check checksum if available
- [ ] Verify disk space available
- [ ] Stop related services
- [ ] Create current backup (safety)
- [ ] Notify users of downtime
- [ ] Verify database/server connectivity

## Post-Restore Checklist

- [ ] Verify data integrity
- [ ] Check database connections
- [ ] Restart services
- [ ] Run application tests
- [ ] Update monitoring
- [ ] Notify users
- [ ] Document restore process

## Troubleshooting

### Restore Fails

```bash
# Check file exists
ls -la backups/postgres_*.sql.gz

# Check disk space
df -h

# Check permissions
ls -la backups/

# Check log file
tail -50 logs/restore_*.log
```

### Database Lock Issues

```bash
# Check active connections
docker exec postgres psql -U postgres -c "SELECT * FROM pg_stat_activity;"

# Force terminate connections
docker exec postgres psql -U postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='appdb';"
```

### Disk Space Issues

```bash
# Check available space
df -h

# Check directory sizes
du -sh backups/*

# Compress or move old backups
gzip backups/old_backup.sql
```

### Permission Issues

```bash
# Fix ownership
chown -R $(id -u):$(id -g) backups/

# Fix permissions
chmod 600 backups/*.sql.gz
```

## Emergency Restore

If data is critical and regular restore fails:

### 1. Scale Down Application

```bash
kubectl scale deployment app --replicas=0
docker-compose stop app
```

### 2. Verify Latest Backup

```bash
./backup.sh list
ls -la backups/
```

### 3. Force Restore

```bash
./restore.sh --force --type postgres --file backup.sql.gz
```

### 4. Verify Data

```bash
docker exec postgres psql -U postgres -c "SELECT count(*) FROM users;"
docker exec postgres psql -U postgres -c "SELECT max(created_at) FROM users;"
```

### 5. Scale Up

```bash
kubectl scale deployment app --replicas=3
docker-compose start app
```

## Automated Restore Testing

Regularly test restores to ensure backups work:

```bash
#!/bin/bash
# test-restore.sh

# Restore to test database
./restore.sh postgres \
    --file $(ls -t backups/postgres_*.sql.gz | head -1) \
    --database testdb \
    --target /tmp/test_restore

# Verify
docker exec postgres psql -U postgres testdb -c "SELECT 1;"

# Cleanup
docker exec postgres psql -U postgres -c "DROP DATABASE testdb;"
```
