# Uptime Kuma

Self-hosted monitoring tool for HTTP/S, TCP, and ping checks.

## Overview

Uptime Kuma provides:
- HTTP/HTTPS monitoring
- TCP port monitoring
- Ping monitoring
- Certificate expiration checks
- Status pages
- Multi-channel notifications

## Quick Start

```bash
cd vps-monitoring/uptime-kuma
docker-compose up -d
```

## Access

- **Uptime Kuma**: http://localhost:3001
- Create your admin account on first login

## Features

### Monitor Types

| Type | Description |
|------|-------------|
| HTTP(s) | Monitor web endpoints |
| TCP | Monitor TCP ports |
| Ping | ICMP ping checks |
| DNS | DNS resolution checks |
| Push | External check reporting |

### Notifications

| Channel | Setup |
|---------|-------|
| Slack | Webhook URL |
| Telegram | Bot Token + Chat ID |
| Email | SMTP settings |
| Discord | Webhook URL |
| Webhook | Custom HTTP endpoint |
| PagerDuty | Integration key |
| Pushover | API Token |
| Gotify | Server URL |

### Status Pages

Create public status pages for your services:
- Beautiful design
- Automatic updates
- Incident history
- Maintenance mode

## Configuration

### Environment Variables

```bash
UPTIME_KUMA_PORT=3001
```

### Push Monitors

For external checks:

1. Create Push monitor
2. Note the slug
3. From external system:
```bash
curl "https://your-kuma.domain/api/push/slug-here"
```

## Monitoring Examples

### HTTP Check

```yaml
Name: My Website
Type: HTTP(s)
URL: https://example.com
Heartbeat interval: 60 seconds
```

### TCP Check

```yaml
Name: SSH Server
Type: TCP
Port: 22
Hostname: example.com
```

### SSL Certificate Check

```yaml
Name: SSL Expiry
Type: HTTP(s)
URL: https://example.com
Certificate expiry check: Enabled
Warning: 30 days
Critical: 7 days
```

## Notifications Setup

### Slack

1. Go to Settings → Notifications → Add Slack
2. Enter Webhook URL
3. Test notification

### Telegram

1. Create bot via @BotFather
2. Get Chat ID
3. Add Telegram notification
4. Configure bot token and chat ID

### Email (SMTP)

1. Go to Settings → Notifications → Add Email
2. Configure SMTP settings
3. Test notification

## API

Uptime Kuma provides a REST API:

```bash
# Login
curl -X POST http://localhost:3001/api/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"password"}'

# Get monitors
curl http://localhost:3001/api/monitors \
  -H "Authorization: Bearer <token>"
```

## Backup

### Docker Volume

```bash
docker stop uptime-kuma
docker run --rm -v uptime_kuma_data:/data -v $(pwd):/backup alpine \
    tar czf /backup/uptime-kuma-backup.tar.gz -C /data .
docker start uptime-kuma
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs uptime-kuma

# Check port
netstat -tlnp | grep 3001
```

### Notifications Not Working

1. Test notification manually
2. Check webhook URLs
3. Verify network access

## Maintenance

### Update

```bash
docker-compose pull
docker-compose up -d
```

### Reset Password

```bash
docker exec -it uptime-kuma node server/reset-password.js
```
