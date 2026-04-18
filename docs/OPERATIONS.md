# Operations Guide

This file contains quick operational reminders for the VPS starter kit.

## Common Commands

### Check running containers
```bash
docker ps -a
```

### Follow logs for a service
```bash
docker compose logs -f
```

### Restart a service
```bash
docker compose restart
```

### Inspect shared networks
```bash
docker network inspect proxy_network
docker network inspect db_network
```

## Recommended Routine

### Daily
- check backups
- check disk space
- check running containers
- review failed deployments if any
- verify important app health endpoints

### Weekly
- verify SSL certificates
- inspect restart counts
- prune unused Docker images carefully
- review monitoring dashboards

### Monthly
- test restore for one backup
- review VPS resource usage
- review outdated images
- review SSH access and admin access
