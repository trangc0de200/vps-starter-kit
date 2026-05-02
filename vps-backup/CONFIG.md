# Configuration Reference

Complete reference for VPS Backup configuration.

## Environment Variables

### General Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_PROVIDER` | local | Backup destination |
| `BACKUP_DIR` | ./backups | Local backup directory |
| `RETENTION_DAYS` | 30 | Backup retention in days |
| `COMPRESSION_LEVEL` | 6 | Gzip compression (1-9) |
| `ENCRYPTION` | false | Enable encryption |
| `ENCRYPTION_PASSWORD` | - | Encryption password |
| `ENABLE_CHECKSUM` | true | Generate SHA-256 checksums |

### AWS S3

| Variable | Default | Description |
|----------|---------|-------------|
| `AWS_ACCESS_KEY_ID` | - | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | - | AWS Secret Key |
| `AWS_DEFAULT_REGION` | us-east-1 | AWS Region |
| `S3_BUCKET` | vps-backups | S3 Bucket name |
| `S3_PREFIX` | backups/ | S3 key prefix |
| `S3_STORAGE_CLASS` | STANDARD_IA | Storage class |

### Backblaze B2

| Variable | Default | Description |
|----------|---------|-------------|
| `B2_ACCOUNT_ID` | - | B2 Account ID |
| `B2_APPLICATION_KEY` | - | B2 Application Key |
| `B2_BUCKET` | vps-backups | B2 Bucket name |

### MinIO

| Variable | Default | Description |
|----------|---------|-------------|
| `MINIO_ENDPOINT` | s3.example.com:9000 | MinIO endpoint |
| `MINIO_ACCESS_KEY` | - | MinIO Access Key |
| `MINIO_SECRET_KEY` | - | MinIO Secret Key |
| `MINIO_BUCKET` | vps-backups | MinIO Bucket |

### rsync

| Variable | Default | Description |
|----------|---------|-------------|
| `RSYNC_HOST` | - | Remote host |
| `RSYNC_USER` | - | SSH username |
| `RSYNC_PORT` | 22 | SSH port |
| `RSYNC_PATH` | /backups | Remote path |
| `RSYNC_BWLIMIT` | - | Bandwidth limit (KB/s) |

### PostgreSQL

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_HOST` | postgres | PostgreSQL host |
| `POSTGRES_PORT` | 5432 | PostgreSQL port |
| `POSTGRES_DB` | appdb | Database name |
| `POSTGRES_USER` | postgres | Database user |
| `POSTGRES_PASSWORD` | - | Database password |

### MySQL

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_HOST` | mysql | MySQL host |
| `MYSQL_PORT` | 3306 | MySQL port |
| `MYSQL_DB` | appdb | Database name |
| `MYSQL_USER` | root | Database user |
| `MYSQL_PASSWORD` | - | Database password |

### Redis

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_HOST` | redis | Redis host |
| `REDIS_PORT` | 6379 | Redis port |
| `REDIS_PASSWORD` | - | Redis password |

### File Backup

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKUP_PATHS` | /home /var/www | Paths to backup |
| `EXCLUDE_PATHS` | - | Exclude patterns |

### Notifications

| Variable | Default | Description |
|----------|---------|-------------|
| `SLACK_WEBHOOK_URL` | - | Slack webhook |
| `ALERT_ON_FAILURE` | true | Alert on failure |
| `ALERT_ON_SUCCESS` | false | Alert on success |
| `HEALTHCHECKS_URL` | - | Healthchecks.io URL |

## Example Configurations

### Basic Local Backup

```bash
BACKUP_PROVIDER=local
LOCAL_BACKUP_PATH=/mnt/backups
RETENTION_DAYS=30
ENABLE_CHECKSUM=true
```

### AWS S3 Backup

```bash
BACKUP_PROVIDER=s3
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
AWS_DEFAULT_REGION=ap-southeast-1
S3_BUCKET=my-vps-backups
S3_PREFIX=production/
S3_STORAGE_CLASS=GLACIER
```

### Backblaze B2 Backup

```bash
BACKUP_PROVIDER=b2
B2_ACCOUNT_ID=your_account_id
B2_APPLICATION_KEY=your_application_key
B2_BUCKET=vps-backups
```

### MinIO Backup

```bash
BACKUP_PROVIDER=minio
MINIO_ENDPOINT=s3.example.com:9000
MINIO_ACCESS_KEY=your_access_key
MINIO_SECRET_KEY=your_secret_key
MINIO_BUCKET=vps-backups
```

### Encrypted Backup

```bash
ENCRYPTION=true
ENCRYPTION_PASSWORD=your_secure_password_here
ENABLE_CHECKSUM=true
```

### Full Configuration

```bash
# Provider
BACKUP_PROVIDER=s3

# PostgreSQL
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=appdb
POSTGRES_USER=postgres
POSTGRES_PASSWORD=secret_password

# MySQL
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DB=appdb
MYSQL_USER=root
MYSQL_PASSWORD=secret_password

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=secret_password

# S3
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
S3_BUCKET=vps-backups
S3_PREFIX=backups/
S3_STORAGE_CLASS=STANDARD_IA

# File backup
BACKUP_PATHS="/home /var/www /etc"
EXCLUDE_PATHS="--exclude='*.log' --exclude='.cache' --exclude='node_modules'"

# Options
ENCRYPTION=true
ENCRYPTION_PASSWORD=backup_encryption_password
ENABLE_CHECKSUM=true
COMPRESSION_LEVEL=6
RETENTION_DAYS=30

# Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/XXX/YYY/ZZZ
ALERT_ON_FAILURE=true
ALERT_ON_SUCCESS=false
HEALTHCHECKS_URL=https://hc-ping.com/your-uuid
```

## Docker Compose Configuration

```yaml
version: '3.8'

services:
  backup:
    image: alpine:latest
    container_name: vps-backup
    restart: unless-stopped
    environment:
      - BACKUP_PROVIDER=${BACKUP_PROVIDER}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
      - S3_BUCKET=${S3_BUCKET}
    volumes:
      - ./backup.sh:/backup.sh:ro
      - ./backups:/backups
      - ./logs:/logs
      - /var/lib/docker/volumes:/docker/volumes:ro
    volumes_from:
      - postgres
      - mysql
    command: ["/backup.sh", "run", "--all"]
    networks:
      - backup_network

networks:
  backup_network:
    name: backup_network
    driver: bridge
```

## Crontab Configuration

```bash
# /etc/crontab

# Hourly backup (every 6 hours)
0 */6 * * * root cd /opt/vps-backup && ./backup.sh run --hourly >> logs/hourly.log 2>&1

# Daily backup (midnight)
0 0 * * * root cd /opt/vps-backup && ./backup.sh run --daily >> logs/daily.log 2>&1

# Weekly backup (Sunday midnight)
0 0 * * 0 root cd /opt/vps-backup && ./backup.sh run --weekly >> logs/weekly.log 2>&1

# Monthly backup (1st of month midnight)
0 0 1 * * root cd /opt/vps-backup && ./backup.sh run --monthly >> logs/monthly.log 2>&1

# Cleanup (daily at 3 AM)
0 3 * * * root cd /opt/vps-backup && ./backup.sh cleanup >> logs/cleanup.log 2>&1

# Verify backups (daily at 4 AM)
0 4 * * * root cd /opt/vps-backup && ./backup.sh verify >> logs/verify.log 2>&1
```

## Retention Configuration

### GFS Rotation

```bash
RETENTION_HOURLY=4      # Keep 4 hourly backups
RETENTION_DAILY=7       # Keep 7 daily backups
RETENTION_WEEKLY=4      # Keep 4 weekly backups
RETENTION_MONTHLY=12    # Keep 12 monthly backups
```

### Custom Retention

```bash
# Keep hourly backups for 6 hours
RETENTION_HOURLY=6

# Keep daily backups for 14 days
RETENTION_DAILY=14

# Keep weekly backups for 8 weeks
RETENTION_WEEKLY=8

# Keep monthly backups for 24 months
RETENTION_MONTHLY=24
```

## Compression Options

| Level | Speed | Compression | Use Case |
|-------|-------|-------------|----------|
| 1 | Fastest | Lowest | Fast backup needed |
| 3 | Fast | Good | Daily backups |
| 6 | Balanced | Better | Default |
| 9 | Slowest | Best | Archive backups |

```bash
COMPRESSION_LEVEL=6
```

## Encryption

### Using openssl

```bash
ENCRYPTION=true
ENCRYPTION_PASSWORD=your_password
```

### Using GPG

```bash
# Generate key
gpg --gen-key

# Use in script
gpg --encrypt --recipient backup@example.com --output backup.tar.gz.gpg backup.tar.gz
```

## Backup Paths

### Common Paths

```bash
# Web applications
BACKUP_PATHS="/var/www /home /etc/nginx /etc/php"

# Databases
# (Handled separately via backup_postgres/backup_mysql)

# Docker volumes
# (Handled via backup_docker_volumes)
```

### Exclude Patterns

```bash
EXCLUDE_PATHS="--exclude='*.log' \
               --exclude='.git' \
               --exclude='node_modules' \
               --exclude='vendor' \
               --exclude='.cache' \
               --exclude='tmp/*' \
               --exclude='*.tmp' \
               --exclude='*.swp' \
               --exclude='*.bak'"
```

## Network Bandwidth

### rsync Bandwidth

```bash
RSYNC_BWLIMIT=1000  # KB/s (1 MB/s)
```

### AWS S3 Multipart

```bash
# S3 Transfer Acceleration
aws configure set default.s3.max_concurrent_requests 10
aws configure set default.s3.max_queue_size 1000
```

## Security

### IAM Policy (AWS)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::vps-backups",
                "arn:aws:s3:::vps-backups/*"
            ]
        }
    ]
}
```

### S3 Bucket Policy

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::vps-backups",
                "arn:aws:s3:::vps-backups/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
```
