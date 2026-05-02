# Shared Infrastructure Scripts

Operational utilities for managing VPS infrastructure across all projects.

## Overview

These scripts provide consistent operational tooling for monitoring, backups, security, and maintenance across the entire VPS platform.

## Scripts Directory

```
scripts/
├── healthcheck_all.sh       # Check all services
├── check_containers.sh      # Container status
├── check_disk_usage.sh     # Disk monitoring
├── check_ssl_expiry.sh      # SSL certificate monitoring
├── check_endpoints.sh       # HTTP endpoint checks
├── show_vps_info.sh         # VPS information
├── backup_all.sh            # Backup all data
├── verify_backups.sh        # Validate backups
├── audit_security.sh        # Security audit
├── review_open_ports.sh     # Port audit
├── review_ufw.sh            # Firewall review
├── cleanup.sh               # Clean old data
├── apply_retention.sh       # Apply retention policy
├── register_service.sh      # Register new service
├── register_project.sh      # Register new project
├── create_app.sh           # Create new app template
├── bootstrap_service.sh     # Bootstrap service
├── rollback_app.sh         # Rollback application
├── platform_status.sh      # Platform overview
├── validate_config.sh       # Config validation
├── list_services.sh        # List all services
└── sync_offsite_placeholder.sh  # Offsite sync placeholder
```

## Usage

### Health Monitoring

```bash
# Check all services
./healthcheck_all.sh

# Check container status
./check_containers.sh

# Check disk usage
./check_disk_usage.sh

# Check SSL expiry
./check_ssl_expiry.sh

# Check endpoints
./check_endpoints.sh
```

### Operations

```bash
# Show VPS info
./show_vps_info.sh

# Backup all
./backup_all.sh

# Verify backups
./verify_backups.sh

# Cleanup old data
./cleanup.sh
```

### Security

```bash
# Security audit
./audit_security.sh

# Review open ports
./review_open_ports.sh

# Review firewall
./review_ufw.sh
```

### Application Management

```bash
# Register new service
./register_service.sh myapp

# Register new project
./register_project.sh myproject

# Create new app
./create_app.sh myapp

# Bootstrap service
./bootstrap_service.sh myservice

# Rollback app
./rollback_app.sh myapp
```

### Platform

```bash
# Platform status
./platform_status.sh

# List services
./list_services.sh

# Validate configs
./validate_config.sh
```

## Scripts Details

### healthcheck_all.sh

Check health status of all services across the platform.

```bash
./healthcheck_all.sh
# Output:
# [OK] postgres:5432 - Healthy
# [OK] mysql:3306 - Healthy
# [OK] redis:6379 - Healthy
# [OK] nginx:80 - Healthy
```

### check_containers.sh

Display status of all Docker containers.

```bash
./check_containers.sh
# Output:
# CONTAINER ID   NAME              STATUS
# abc123...      postgres          running
# def456...      mysql             running
```

### check_disk_usage.sh

Monitor disk usage across all mounted volumes.

```bash
./check_disk_usage.sh
# Output:
# Filesystem      Size  Used Avail Use% Mounted on
# /dev/sda1       100G   45G   55G  45% /
```

### check_ssl_expiry.sh

Check SSL certificate expiration dates.

```bash
./check_ssl_expiry.sh
# Output:
# Domain: example.com
# Expiry: 2024-12-31 (90 days remaining)
# Status: OK
```

### check_endpoints.sh

HTTP health check for configured endpoints.

```bash
./check_endpoints.sh
# Output:
# http://localhost/health - 200 OK
# http://api.local/health - 200 OK
```

### show_vps_info.sh

Display system information.

```bash
./show_vps_info.sh
# Output:
# Hostname: vps-01
# OS: Ubuntu 22.04
# Kernel: 5.15.0
# CPU: 2 vCPU
# Memory: 4GB
# Disk: 100GB
# Uptime: 30 days
```

### backup_all.sh

Backup all data across services.

```bash
./backup_all.sh
# Creates timestamped backups in ./backups/
```

### audit_security.sh

Comprehensive security audit.

```bash
./audit_security.sh
# Checks:
# - Open ports
# - UFW status
# - Failed login attempts
# - Docker security
# - SSL certificates
```

### review_open_ports.sh

List all listening network ports.

```bash
./review_open_ports.sh
# Output:
# Port   Service   PID
# 22     sshd      1234
# 80     nginx     2345
# 443    nginx     2345
```

### review_ufw.sh

Check UFW firewall configuration.

```bash
./review_ufw.sh
# Output:
# Status: active
# To                         Action      From
# --                         ------      ----
# 22/tcp                     ALLOW       Anywhere
# 80/tcp                     ALLOW       Anywhere
# 443/tcp                    ALLOW       Anywhere
```

### cleanup.sh

Clean up old logs, temp files, unused images.

```bash
./cleanup.sh
# Options:
#   --logs       Remove old logs
#   --images     Remove unused images
#   --containers Remove stopped containers
#   --volumes    Remove unused volumes
#   --all        All of the above
```

### apply_retention.sh

Apply data retention policies.

```bash
./apply_retention.sh
# Removes data older than retention period
```

### register_service.sh

Register a new service in the platform.

```bash
./register_service.sh myservice
# Creates:
# - Service configuration
# - Health check
# - Backup job
```

### create_app.sh

Scaffold a new application.

```bash
./create_app.sh myapp
# Creates:
# - Directory structure
# - docker-compose.yml
# - .env.example
# - README.md
```

## Cron Jobs

Example crontab configuration:

```bash
# /shared/cron/example-crontab.txt

# Health checks every 5 minutes
*/5 * * * * /path/to/scripts/healthcheck_all.sh >> /var/log/healthcheck.log 2>&1

# Disk check hourly
0 * * * * /path/to/scripts/check_disk_usage.sh >> /var/log/disk.log 2>&1

# SSL check daily
0 0 * * * /path/to/scripts/check_ssl_expiry.sh >> /var/log/ssl.log 2>&1

# Backup daily at 2 AM
0 2 * * * /path/to/scripts/backup_all.sh >> /var/log/backup.log 2>&1

# Security audit weekly
0 3 * * 0 /path/to/scripts/audit_security.sh >> /var/log/security.log 2>&1

# Cleanup weekly
0 4 * * 0 /path/to/scripts/cleanup.sh --all >> /var/log/cleanup.log 2>&1
```

## Requirements

- Docker & Docker Compose
- UFW (optional)
- Root/sudo access for some scripts
- curl, netstat, df (standard Linux utilities)

## Configuration

Scripts read configuration from environment or config files:

```bash
# .env file
BACKUP_DIR=/var/backups
RETENTION_DAYS=30
ALERT_EMAIL=admin@example.com
SLACK_WEBHOOK=https://hooks.slack.com/...
```

## Exit Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Service unavailable |
| 4 | Permission denied |

## Logging

All scripts log to:

- stdout (for cron)
- `/var/log/{script-name}.log` (if running as root)
- `./logs/{script-name}.log` (if running as user)

## Contributing

When adding new scripts:

1. Follow bash best practices
2. Add shebang `#!/usr/bin/env bash`
3. Include `set -euo pipefail`
4. Add `--help` option
5. Include logging with timestamps
6. Document in this README
