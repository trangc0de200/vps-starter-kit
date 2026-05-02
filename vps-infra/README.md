# VPS Infrastructure Stack

Production-ready infrastructure components for VPS deployments including reverse proxy, SSL management, monitoring, and operational utilities.

## Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                          INTERNET                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Nginx Proxy Manager                          │
│              (SSL Termination / Reverse Proxy)                  │
│                    Port: 80, 443, 81                            │
└────────────────────────────┬────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  Application  │    │  Application  │    │  Application  │
│    (App 1)    │    │    (App 2)    │    │    (App 3)    │
└───────────────┘    └───────────────┘    └───────────────┘
```

## Components

### Core Infrastructure

| Component | Path | Description |
|-----------|------|-------------|
| [Nginx Proxy Manager](nginx-proxy-manager/) | Port 80/443 | Reverse proxy with Web UI |
| [Shared Scripts](shared/) | - | Operational utilities |

### Available Components

| Component | Port | Status |
|-----------|------|--------|
| [Nginx Proxy Manager](nginx-proxy-manager/) | 80, 443, 81 | Ready |
| Traefik | 80, 443 | Planned |
| Caddy | 80, 443 | Planned |
| HAProxy | 80, 443 | Planned |

## Quick Start

### Nginx Proxy Manager

```bash
cd vps-infra/nginx-proxy-manager
cp .env.example .env
docker-compose up -d

# Access Web UI
open http://localhost:81
# Default: admin@example.com / changeme
```

### Run All Checks

```bash
cd vps-infra/shared
./scripts/healthcheck_all.sh
./scripts/check_disk_usage.sh
./scripts/check_containers.sh
```

## Features

### Nginx Proxy Manager

- **Web UI**: Easy SSL certificate management
- **Let's Encrypt**: Free automatic SSL
- **Custom SSL**: Upload your own certificates
- **Access Lists**: IP whitelisting
- **Rate Limiting**: Protect against DDoS
- **HTTP/2**: Modern protocol support
- **Cloudflare**: Built-in DNS provider support

### Shared Utilities

- **Health Checks**: Monitor all services
- **SSL Monitoring**: Track certificate expiry
- **Disk Usage**: Monitor storage
- **Container Management**: Start/stop/restart
- **Backup Verification**: Validate backups
- **Security Audit**: Check open ports, UFW status

## Architecture

### Network Ports

| Port | Service | Description |
|------|---------|-------------|
| 80 | HTTP | Web traffic (redirects to HTTPS) |
| 443 | HTTPS | Secure web traffic |
| 81 | Admin UI | Nginx Proxy Manager dashboard |
| 3000+ | Applications | Application ports |

### SSL/TLS

- Automatic Let's Encrypt certificates
- Custom certificate support
- Certificate renewal automation
- Multi-domain SAN certificates

## Management

### Container Management

```bash
# Start all
docker-compose up -d

# Stop all
docker-compose down

# View logs
docker-compose logs -f

# Restart specific service
docker-compose restart nginx-proxy-manager
```

### SSL Certificate Management

```bash
# Check certificate expiry
./shared/scripts/check_ssl_expiry.sh

# Renew certificates
# (Automated via Nginx Proxy Manager UI)
```

### Security Audit

```bash
# Review open ports
./shared/scripts/review_open_ports.sh

# Review UFW firewall
./shared/scripts/review_ufw.sh

# Security audit
./shared/scripts/audit_security.sh
```

## Monitoring

### Health Checks

```bash
# Check all containers
./shared/scripts/healthcheck_all.sh

# Check specific endpoints
./shared/scripts/check_endpoints.sh

# Container status
./shared/scripts/check_containers.sh
```

### Disk & Resources

```bash
# Disk usage
./shared/scripts/check_disk_usage.sh

# Show VPS info
./shared/scripts/show_vps_info.sh
```

## Backup & Restore

### Backup All

```bash
./shared/scripts/backup_all.sh
```

### Verify Backups

```bash
./shared/scripts/verify_backups.sh
```

## Troubleshooting

### Common Issues

#### Nginx Proxy Manager Won't Start

```bash
# Check logs
docker-compose logs nginx-proxy-manager

# Check port conflicts
netstat -tlnp | grep -E '80|443|81'

# Restart
docker-compose down && docker-compose up -d
```

#### SSL Certificate Issues

```bash
# Check Let's Encrypt logs
docker-compose logs nginx-proxy-manager | grep -i le

# Manual renewal
# Go to SSL Certificates > Click Renew
```

#### 502 Bad Gateway

```bash
# Check if backend is running
docker ps

# Check backend logs
docker logs <backend-container>

# Verify proxy host configuration
# Go to Hosts > Proxy Hosts > Edit
```

## Security

### Best Practices

1. **Change default passwords** immediately
2. **Use strong SSL certificates**
3. **Enable firewall** (UFW)
4. **Regular backups**
5. **Monitor logs**
6. **Keep software updated**

### Firewall Configuration

```bash
# Allow only necessary ports
ufw allow 22    # SSH
ufw allow 80     # HTTP
ufw allow 443    # HTTPS
ufw allow 81    # NPM Admin (optional, consider IP restriction)
ufw enable
```

## Contributing

### Adding New Components

1. Create component folder under `vps-infra/`
2. Add `docker-compose.yml`
3. Add `.env.example`
4. Add `README.md`
5. Update this README

### Scripts Guidelines

- Use `#!/usr/bin/env bash`
- Add error handling with `set -euo pipefail`
- Include `--help` option
- Log with timestamps

## Documentation

- [Nginx Proxy Manager](nginx-proxy-manager/README.md)
- [Shared Scripts](shared/README.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Security Guide](docs/SECURITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
