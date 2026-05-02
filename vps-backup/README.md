# VPS Backup System

Enterprise-grade automated backup solution with multi-cloud support, encryption, and retention policies.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         VPS Backup                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │PostgreSQL│  │  MySQL   │  │  Files   │  │ Docker   │       │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
│       │              │              │              │              │
│       └──────────────┴──────────────┴──────────────┘              │
│                           │                                       │
│                           ▼                                       │
│                    ┌─────────────┐                                │
│                    │ Compression │                                │
│                    │ Encryption  │                                │
│                    └──────┬──────┘                                │
│                           │                                       │
│                           ▼                                       │
│                    ┌─────────────┐                                │
│                    │   Upload    │                                │
│                    └──────┬──────┘                                │
│                           │                                       │
│       ┌───────────────────┼───────────────────┐                  │
│       ▼                   ▼                   ▼                  │
│  ┌─────────┐         ┌─────────┐         ┌─────────┐           │
│  │   S3   │         │   B2    │         │  Local  │           │
│  └─────────┘         └─────────┘         └─────────┘           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- **Multi-Database Support**: PostgreSQL, MySQL, MariaDB, Redis
- **File Backups**: Tar/gzip with exclude patterns
- **Docker Volumes**: Full volume backup
- **Multi-Cloud**: AWS S3, Backblaze B2, MinIO, rsync, local
- **Encryption**: AES-256 encryption at rest
- **Compression**: Gzip with configurable level
- **Retention**: GFS rotation (Hourly/Daily/Weekly/Monthly)
- **Verification**: SHA-256 checksum validation
- **Notifications**: Integration with alerting system

## Quick Start

### 1. Configure

```bash
cd vps-backup
cp .env.example .env
nano .env
```

### 2. Run Backup

```bash
# All backups
./backup.sh run --all

# Specific type
./backup.sh run --daily
./backup.sh run --postgres
./backup.sh run --files weekly
```

### 3. Verify

```bash
# List backups
./backup.sh list

# Check status
./backup.sh status
```

### 4. Schedule (Crontab)

```bash
# Edit crontab
crontab -e

# Add backup jobs
0 */6 * * * cd /opt/vps-backup && ./backup.sh run --hourly >> logs/hourly.log 2>&1
0 0 * * * cd /opt/vps-backup && ./backup.sh run --daily >> logs/daily.log 2>&1
0 0 * * 0 cd /opt/vps-backup && ./backup.sh run --weekly >> logs/weekly.log 2>&1
0 0 1 * * cd /opt/vps-backup && ./backup.sh run --monthly >> logs/monthly.log 2>&1
```

## Backup Types

| Type | Schedule | Content | Retention |
|------|----------|---------|-----------|
| `--hourly` | Every 6 hours | Databases only | 24 hours |
| `--daily` | Daily at midnight | DB + Files | 7 days |
| `--weekly` | Sundays | Full backup | 4 weeks |
| `--monthly` | 1st of month | Full backup + Volumes | 12 months |
| `--all` | Manual | Everything | Per retention |

## Cloud Providers

### AWS S3

```bash
# Environment
BACKUP_PROVIDER=s3
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
S3_BUCKET=vps-backups
S3_PREFIX=backups/
S3_STORAGE_CLASS=STANDARD_IA
```

### Backblaze B2

```bash
# Environment
BACKUP_PROVIDER=b2
B2_ACCOUNT_ID=your_account_id
B2_APPLICATION_KEY=your_application_key
B2_BUCKET=vps-backups
```

### MinIO (Self-hosted S3)

```bash
# Environment
BACKUP_PROVIDER=minio
MINIO_ENDPOINT=s3.example.com:9000
MINIO_ACCESS_KEY=your_access_key
MINIO_SECRET_KEY=your_secret_key
MINIO_BUCKET=vps-backups
```

### Local/NAS

```bash
# Environment
BACKUP_PROVIDER=local
LOCAL_BACKUP_PATH=/mnt/backups
```

### rsync

```bash
# Environment
BACKUP_PROVIDER=rsync
RSYNC_HOST=backup.example.com
RSYNC_USER=backup
RSYNC_PORT=22
RSYNC_PATH=/backups
```

## Database Configuration

### PostgreSQL

```bash
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=appdb
POSTGRES_USER=postgres
# POSTGRES_PASSWORD from .env
```

### MySQL

```bash
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DB=appdb
MYSQL_USER=root
# MYSQL_PASSWORD from .env
```

### Redis

```bash
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_password
```

## File Backups

### Configure Paths

```bash
BACKUP_PATHS="/home /var/www /etc"
EXCLUDE_PATHS="--exclude='*.log' --exclude='.cache' --exclude='node_modules'"
```

### Exclude Patterns

```bash
# Common exclusions
EXCLUDE_PATHS="--exclude='*.log' \
               --exclude='.git' \
               --exclude='node_modules' \
               --exclude='vendor' \
               --exclude='.cache' \
               --exclude='tmp/*'"
```

## Encryption

Enable AES-256 encryption:

```bash
ENCRYPTION=true
ENCRYPTION_PASSWORD=your_secure_password
```

Encrypted backups have `.enc` extension.

## Verification

Enable checksum verification:

```bash
ENABLE_CHECKSUM=true
```

To verify a backup:

```bash
# Verify local
sha256sum backup.tar.gz
cat backup.tar.gz.sha256

# Verify remote (S3)
aws s3 cp s3://bucket/backup.tar.gz - | sha256sum
```

## Restore

See [RESTORE.md](RESTORE.md) for detailed restore instructions.

### Quick Restore

```bash
# Interactive restore
./restore.sh interactive

# Restore specific backup
./restore.sh postgres --file backups/postgres_20240115.sql.gz

# Restore to specific database
./restore.sh postgres --file backup.dump --database newdb
```

## Monitoring

### Integration with Alerting

```bash
# In .env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/ZZZ
ALERT_ON_FAILURE=true
ALERT_ON_SUCCESS=false
```

### Log Files

```bash
# View logs
tail -f logs/backup_*.log

# Backup logs location
logs/
├── backup_20240115_120000.log
├── backup_20240115_180000.log
└── backup_20240116_000000.log
```

### Healthchecks.io

```bash
# In .env
HEALTHCHECKS_URL=https://hc-ping.com/your-uuid
```

## Troubleshooting

### Backup Fails

1. Check logs: `tail -f logs/backup_*.log`
2. Verify credentials
3. Check disk space
4. Verify database connectivity

### Upload Fails

```bash
# Test S3 credentials
aws s3 ls s3://bucket/

# Test B2 credentials
b2 list_buckets

# Test rsync connection
ssh user@host "ls /backups"
```

### Database Not Running

```bash
# Check container status
docker ps | grep -E 'postgres|mysql|redis'

# Check connectivity
docker exec postgres pg_isready
docker exec mysql mysqladmin ping
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean old backups manually
./backup.sh cleanup

# Remove old log files
find logs/ -name "*.log" -mtime +30 -delete
```

## Retention Policy

Default retention (can be customized):

| Backup Type | Keep |
|-------------|------|
| Hourly | 4 copies |
| Daily | 7 days |
| Weekly | 4 weeks |
| Monthly | 12 months |

### Custom Retention

```bash
RETENTION_HOURLY=6
RETENTION_DAILY=7
RETENTION_WEEKLY=4
RETENTION_MONTHLY=12
```

## Performance

### Compression Level

```bash
# 1 = fastest, 9 = best compression
COMPRESSION_LEVEL=6
```

### Parallel Uploads

```bash
# For S3
aws s3 cp --storage-class STANDARD_IA --no-progress
```

### Bandwidth Limiting

```bash
# rsync bandwidth limit (KB/s)
RSYNC_BWLIMIT=1000
```

## Security

### Best Practices

1. **Use encryption** for sensitive data
2. **Rotate passwords** regularly
3. **Restrict IAM permissions** (least privilege)
4. **Enable versioning** on S3 bucket
5. **Use private networking** for backups

### IAM Policy (AWS S3)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::vps-backups/*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::vps-backups"
        }
    ]
}
```

## File Structure

```
vps-backup/
├── README.md           # This file
├── RESTORE.md         # Restore guide
├── CONFIG.md          # Configuration reference
├── docker-compose.yml # Docker deployment
├── .env.example       # Environment template
├── backup.sh          # Main backup script
├── restore.sh         # Restore script
├── schedule.sh        # Cron scheduler
├── backups/           # Local backups (gitignored)
├── logs/              # Log files
└── config/            # Configuration files
```

## Scripts

| Script | Description |
|--------|-------------|
| `backup.sh` | Main backup script |
| `restore.sh` | Restore from backup |
| `schedule.sh` | Setup cron jobs |

## Contributing

When adding new backup sources:

1. Add function to `backup.sh`
2. Update help text
3. Update documentation
4. Test thoroughly

## License

MIT
