# VPS App Template

Production-ready application template with deployment, monitoring, and backup scripts.

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                       APPLICATION TEMPLATE                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Deploy    │  │   Health     │  │   Backup     │           │
│  │   Script    │  │   Check      │  │   Script     │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                  │                  │                      │
│         └──────────────────┴──────────────────┘                      │
│                            │                                         │
│         ┌──────────────────┴──────────────────┐                     │
│         │                                       │                     │
│  ┌──────┴───────┐  ┌──────────────┐  ┌───────┴────────┐         │
│  │   Rollback   │  │  Migration   │  │    Logs       │         │
│  │   Script     │  │   Script     │  │    Scripts    │         │
│  └──────────────┘  └──────────────┘  └────────────────┘         │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Quick Start

### 1. Copy Template

```bash
cp -r vps-app/app-template /opt/myapp
cd /opt/myapp
```

### 2. Configure

```bash
# Copy environment files
cp .env.production.example .env
cp .env.staging.example .env.staging

# Edit configuration
nano .env
```

### 3. Deploy

```bash
# Deploy to production
./scripts/deploy.sh --env production

# Deploy to staging
./scripts/deploy.sh --env staging
```

## Directory Structure

```
app-template/
├── README.md                    # This file
├── .gitignore                   # Git ignore
├── .env.production.example     # Production env
├── .env.staging.example       # Staging env
├── docker-compose.yml.example  # Docker compose
├── scripts/
│   ├── deploy.sh              # Deploy script
│   ├── healthcheck.sh         # Health check
│   ├── backup.sh.example      # Backup (copy and edit)
│   ├── rollback.sh            # Rollback script
│   └── migrate.sh             # Database migration
└── nginx/
    └── default.conf           # Nginx config
```

## Environment Configuration

### Production Environment

```bash
# Application
NODE_ENV=production
APP_PORT=3000
APP_DEBUG=false

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=<generate>
DB_SSL_MODE=require

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=<generate>

# Security
SESSION_SECRET=<generate>
JWT_SECRET=<generate>
ENCRYPTION_KEY=<generate>

# Monitoring
PROMETHEUS_ENABLED=true
SENTRY_DSN=https://...
```

## Scripts

### Deploy Script

```bash
./scripts/deploy.sh --env production
```

Options:
- `--env` - Environment (staging/production)
- `--branch` - Git branch (default: main)
- `--backup` - Backup before deploy
- `--migrate` - Run migrations after deploy

### Health Check

```bash
./scripts/healthcheck.sh
```

Exit codes:
- `0` - Healthy
- `1` - Unhealthy
- `2` - Starting

### Backup Script

```bash
# Setup
cp scripts/backup.sh.example scripts/backup.sh
chmod +x scripts/backup.sh

# Run backup
./scripts/backup.sh

# With rotation
./scripts/backup.sh --rotate --keep 7
```

### Rollback Script

```bash
# Rollback to previous version
./scripts/rollback.sh

# Rollback to specific version
./scripts/rollback.sh --version v1.0.0

# List available versions
./scripts/rollback.sh --list
```

### Migration Script

```bash
# Run migrations
./scripts/migrate.sh up

# Rollback migration
./scripts/migrate.sh down

# Status
./scripts/migrate.sh status
```

## Docker Compose

### Example Configuration

```yaml
version: '3.8'

services:
  app:
    build: .
    container_name: myapp
    restart: unless-stopped
    ports:
      - "${APP_PORT:-3000}:3000"
    environment:
      - NODE_ENV=${NODE_ENV}
      - DB_HOST=${DB_HOST}
    volumes:
      - app_data:/data
    networks:
      - proxy_network
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      resources:
        limits:
          memory: 512M

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx:/etc/nginx/conf.d:ro
    depends_on:
      - app
    networks:
      - proxy_network

networks:
  proxy_network:
    external: true

volumes:
  app_data:
    driver: local
```

## Deployment Workflow

```
┌─────────────────────────────────────────────────────────┐
│                    DEPLOYMENT FLOW                        │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  1. Pre-deploy                                          │
│     ├─ Backup current version                            │
│     ├─ Health check                                     │
│     └─ Notify (optional)                                │
│                                                          │
│  2. Deploy                                              │
│     ├─ Pull/Build image                                 │
│     ├─ Run migrations                                   │
│     ├─ Stop old container                               │
│     └─ Start new container                             │
│                                                          │
│  3. Post-deploy                                         │
│     ├─ Health check                                     │
│     ├─ Log deployment                                  │
│     └─ Notify (optional)                                │
│                                                          │
│  4. On Failure                                          │
│     ├─ Auto-rollback (optional)                         │
│     ├─ Notify                                           │
│     └─ Keep backup                                      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## Health Check Endpoint

Your application should expose `/health`:

```javascript
// Express example
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: process.env.APP_VERSION
  });
});
```

## Backup Strategy

### Local Backup

```bash
# Daily backup
0 2 * * * /opt/myapp/scripts/backup.sh

# Weekly backup (Sundays)
0 3 * * 0 /opt/myapp/scripts/backup.sh --compress
```

### Remote Backup

```bash
# Backup to S3
./scripts/backup.sh --destination s3://my-bucket/backups

# Backup to B2
./scripts/backup.sh --destination b2://my-bucket/backups

# Backup to FTP
./scripts/backup.sh --destination ftp://server/backups
```

### Backup Contents

- Database dump
- User uploads
- Application config
- Environment files (encrypted)

## Monitoring

### Prometheus Metrics

Expose `/metrics`:

```javascript
// Prometheus client
const promClient = require('prom-client');
const register = promClient.register;

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.send(await register.metrics());
});
```

### Health Metrics

```bash
# Check health
curl http://localhost:3000/health

# Check metrics
curl http://localhost:3000/metrics
```

## Logging

### Application Logs

```javascript
// Structured logging
console.log(JSON.stringify({
  level: 'info',
  message: 'Request processed',
  timestamp: new Date().toISOString(),
  duration: 150,
  status: 200
}));
```

### Log Shipping

Ship logs to ELK:

```yaml
# docker-compose.yml
app:
  logging:
    driver: fluentd
    options:
      fluentd-address: localhost:24224
      tag: app.{{.Name}}
```

## Security

### Environment Variables

Never commit `.env` files:

```
.env
.env.*
!.env.example
```

### Secrets Management

Use secrets from `vps-secrets`:

```bash
# Load secrets
source ../vps-secrets/.env
```

### File Permissions

```bash
# Scripts
chmod +x scripts/*.sh

# Environment
chmod 600 .env

# SSH keys
chmod 600 keys/*
```

## CI/CD Integration

### GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        run: |
          ./scripts/deploy.sh --env production
        env:
          DEPLOY_KEY: ${{ secrets.DEPLOY_KEY }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml
deploy:
  stage: deploy
  script:
    - ./scripts/deploy.sh --env production
  only:
    - main
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs app

# Check health
./scripts/healthcheck.sh

# Verify env
docker-compose config
```

### Database Connection Failed

```bash
# Check database
docker-compose exec app nc -zv db 5432

# Test connection
docker-compose exec app node -e "require('./db').connect()"
```

### Migration Failed

```bash
# Check migration status
./scripts/migrate.sh status

# Rollback
./scripts/migrate.sh down

# Manual fix and retry
./scripts/migrate.sh up
```

## Best Practices

1. **Always backup** before deploy
2. **Test in staging** first
3. **Use health checks** for all services
4. **Monitor logs** for errors
5. **Rotate logs** regularly
6. **Keep versions** for rollback
7. **Encrypt backups** before remote storage
8. **Use secrets** not hardcoded values

## Documentation

- [Deploy Script](scripts/deploy.sh)
- [Health Check](scripts/healthcheck.sh)
- [Backup Script](scripts/backup.sh.example)
- [Rollback Script](scripts/rollback.sh)
- [Migration Script](scripts/migrate.sh)
