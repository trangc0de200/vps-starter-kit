# VPS Platform

Infrastructure automation and lifecycle management for VPS deployments.

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                      PLATFORM AUTOMATION                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Bootstrap   │  │   Lifecycle   │  │   Registry   │           │
│  │   Project    │  │   Manage     │  │   Track      │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                  │                  │                      │
│         └──────────────────┴──────────────────┘                      │
│                            │                                         │
│         ┌──────────────────┴──────────────────┐                     │
│         │                                       │                     │
│  ┌──────┴───────┐  ┌──────────────┐  ┌───────┴────────┐         │
│  │   Deploy     │  │    Monitor    │  │    Backup      │         │
│  │   Scripts    │  │    Health    │  │    Schedules   │         │
│  └──────────────┘  └──────────────┘  └────────────────┘         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Components

### Scripts

| Script | Description |
|--------|-------------|
| `bootstrap_project.sh` | Initialize new project |
| `lifecycle_restart.sh` | Restart services |
| `lifecycle_redeploy.sh` | Redeploy services |
| `registry_report.sh` | Generate registry report |

### Registry

Track deployed services, versions, and configurations.

## Quick Start

### 1. Bootstrap New Project

```bash
cd vps-platform
./scripts/bootstrap_project.sh --name myapp --path /opt/myapp
```

### 2. Track Services

```bash
./scripts/registry_report.sh --generate
./scripts/registry_report.sh --list
```

### 3. Lifecycle Management

```bash
# Restart services
./scripts/lifecycle_restart.sh --service nginx

# Redeploy services
./scripts/lifecycle_redeploy.sh --service myapp --version latest
```

## Directory Structure

```
vps-platform/
├── README.md
├── .gitignore
├── registry/
│   ├── README.md
│   └── services.json
├── scripts/
│   ├── bootstrap_project.sh
│   ├── lifecycle_restart.sh
│   ├── lifecycle_redeploy.sh
│   ├── registry_report.sh
│   ├── deploy.sh
│   ├── health_check.sh
│   └── migrate.sh
├── templates/
│   ├── docker-compose.yml
│   ├── nginx.conf
│   └── prometheus.yml
└── configs/
    └── platform.yml
```

## Bootstrap

### New Project

```bash
./scripts/bootstrap_project.sh \
    --name myapp \
    --path /opt/myapp \
    --stack docker \
    --monitoring prometheus
```

Creates:
- Project directory structure
- Docker Compose configuration
- Nginx reverse proxy config
- Prometheus monitoring
- Health check endpoints
- Backup schedules

### Project Structure

```
/opt/myapp/
├── docker-compose.yml
├── .env
├── nginx/
│   └──.conf
├── prometheus/
│   └── prometheus.yml
├── backup/
│   └── backup.sh
└── health/
    └── health.sh
```

## Lifecycle Management

### Service States

```
Deploy → Running → Restarting → Stopping → Removed
                ↓
            Updating
```

### Restart Services

```bash
# Restart single service
./scripts/lifecycle_restart.sh --service nginx

# Restart with backup
./scripts/lifecycle_restart.sh --service nginx --backup

# Force restart
./scripts/lifecycle_restart.sh --service nginx --force
```

### Redeploy Services

```bash
# Redeploy latest
./scripts/lifecycle_redeploy.sh --service myapp

# Redeploy specific version
./scripts/lifecycle_redeploy.sh --service myapp --version v1.2.3

# Redeploy all
./scripts/lifecycle_redeploy.sh --all
```

### Rollback

```bash
# Rollback to previous version
./scripts/lifecycle_redeploy.sh --service myapp --rollback

# List available versions
./scripts/lifecycle_redeploy.sh --service myapp --list-versions
```

## Registry

### Service Registry

Track all deployed services:

```json
{
  "services": [
    {
      "name": "myapp",
      "path": "/opt/myapp",
      "version": "v1.2.0",
      "stack": "docker",
      "ports": [3000, 3001],
      "health": "healthy",
      "last_deploy": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Generate Report

```bash
# Full report
./scripts/registry_report.sh --generate

# List services
./scripts/registry_report.sh --list

# Export JSON
./scripts/registry_report.sh --export --format json

# Export CSV
./scripts/registry_report.sh --export --format csv
```

## Deployment

### Deploy Service

```bash
# Deploy from git
./scripts/deploy.sh \
    --name myapp \
    --git https://github.com/user/myapp.git \
    --branch main

# Deploy from image
./scripts/deploy.sh \
    --name myapp \
    --image myregistry/myapp:latest
```

### Deployment Stages

1. **Pre-deploy**: Backup, health check
2. **Deploy**: Pull image, stop old, start new
3. **Post-deploy**: Health check, notify

### Rollback Strategy

```yaml
rollback:
  enabled: true
  keep_versions: 5
  automatic: false
  trigger:
    health_check: false
    metric_threshold: true
```

## Monitoring

### Health Checks

```bash
# Check single service
./scripts/health_check.sh --service myapp

# Check all
./scripts/health_check.sh --all

# Continuous monitoring
./scripts/health_check.sh --watch --interval 30
```

### Health Endpoints

| Endpoint | Port | Description |
|----------|------|-------------|
| /health | 8080 | Basic health |
| /health/ready | 8080 | Readiness probe |
| /health/live | 8080 | Liveness probe |
| /metrics | 9090 | Prometheus metrics |

## Backup Integration

### Automatic Backup

```bash
# Enable backup on deploy
./scripts/deploy.sh --name myapp --backup

# Backup before restart
./scripts/lifecycle_restart.sh --service myapp --backup

# Schedule backup
./scripts/lifecycle_restart.sh --service myapp --backup-schedule "0 2 * * *"
```

### Backup Locations

- Local: `/opt/backups/{service}`
- Remote: S3, B2, MinIO

## Migration

### Database Migration

```bash
# Run migrations
./scripts/migrate.sh --service myapp --step up

# Rollback
./scripts/migrate.sh --service myapp --step down

# Status
./scripts/migrate.sh --service myapp --status
```

## Configuration

### Platform Config

```yaml
# configs/platform.yml
platform:
  name: production
  region: ap-southeast-1
  
  defaults:
    backup: true
    monitoring: true
    health_check: true
    
  limits:
    max_services: 50
    max_memory_per_service: 2G
    
  notifications:
    slack_webhook: "${SLACK_WEBHOOK_URL}"
    on_failure: true
    on_success: false
```

## Integration

### With VPS Backup

```bash
# Trigger backup before deploy
./scripts/deploy.sh --name myapp \
    --pre-deploy-hook "cd ../vps-backup && ./backup.sh run --files"

# Backup on failure
./scripts/deploy.sh --name myapp \
    --on-failure-hook "cd ../vps-backup && ./backup.sh run --all"
```

### With VPS Monitoring

```bash
# Enable Prometheus
./scripts/deploy.sh --name myapp --monitoring prometheus

# Enable Grafana dashboards
./scripts/deploy.sh --name myapp --dashboards grafana
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs myapp

# Check health
./scripts/health_check.sh --service myapp

# Restart
./scripts/lifecycle_restart.sh --service myapp --force
```

### Deploy Fails

```bash
# Verbose output
./scripts/deploy.sh --name myapp --verbose

# Dry run
./scripts/deploy.sh --name myapp --dry-run

# Check registry
./scripts/registry_report.sh --list
```

## Automation

### Cron Jobs

```bash
# Health check every 5 minutes
*/5 * * * * cd /opt/vps-platform && ./scripts/health_check.sh --all

# Registry report daily
0 3 * * * cd /opt/vps-platform && ./scripts/registry_report.sh --generate

# Restart services weekly
0 4 * * 0 cd /opt/vps-platform && ./scripts/lifecycle_restart.sh --all
```

## Best Practices

1. **Always backup** before deploy/restart
2. **Use health checks** for all services
3. **Keep registry updated** for tracking
4. **Monitor continuously** for issues
5. **Document changes** in registry
6. **Test rollback** procedures
7. **Use version tags** for deployments

## CLI Reference

### deploy.sh

```bash
./scripts/deploy.sh [OPTIONS]

Options:
  --name NAME           Service name
  --git URL            Git repository
  --image IMAGE        Docker image
  --branch BRANCH      Git branch
  --version VERSION    Specific version
  --backup            Backup before deploy
  --monitoring        Enable monitoring
  --dry-run           Show what would be done
  --verbose           Verbose output
  --help              Show help
```

### lifecycle_restart.sh

```bash
./scripts/lifecycle_restart.sh [OPTIONS]

Options:
  --service NAME       Service name
  --all               Restart all services
  --backup            Backup before restart
  --force             Force restart
  --timeout SECONDS    Timeout (default: 60)
  --help              Show help
```

### registry_report.sh

```bash
./scripts/registry_report.sh [OPTIONS]

Options:
  --generate          Generate/update report
  --list              List all services
  --export FORMAT     Export (json/csv)
  --service NAME      Filter by service
  --help              Show help
```

## Documentation

- [Registry](registry/README.md)
- [Scripts](scripts/)
- [Templates](templates/)
