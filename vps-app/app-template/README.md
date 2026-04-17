# App Template

This folder is a reusable starting point for a new application deployment.

## Recommended process

```bash
cp -r /opt/vps/vps-app/app-template /opt/vps/vps-app/my-app
cd /opt/vps/vps-app/my-app
cp .env.production.example .env.production
nano .env.production
```

Then customize:
- `docker-compose.yml`
- `scripts/migrate.sh`
- `scripts/healthcheck.sh`
- `scripts/rollback.sh`

This template is intentionally generic.
