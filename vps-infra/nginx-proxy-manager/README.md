# Nginx Proxy Manager

Production-ready Nginx Proxy Manager deployment with automatic SSL, reverse proxy, and access control.

## Overview

Nginx Proxy Manager is a Docker container that provides:

- **Web UI** for managing proxies, SSL certificates, and access lists
- **Automatic SSL** via Let's Encrypt with auto-renewal
- **Reverse Proxy** for forwarding traffic to backend services
- **Access Lists** for IP whitelisting/blacklisting
- **HTTP/2 Support** for modern web performance
- **Rate Limiting** to protect against abuse

## Architecture

```
Internet ──────► NPM (443) ──────► Backend Service
                 │
                 ▼
              NPM (80) ──────► Redirects to HTTPS
                 │
                 ▼
              NPM (81) ──────► Admin UI
```

## Quick Start

```bash
cd vps-infra/nginx-proxy-manager
cp .env.example .env
docker-compose up -d

# Access Admin UI
open http://localhost:81
```

### Default Credentials

| Field | Value |
|-------|-------|
| Email | `admin@example.com` |
| Password | `changeme` |

**Important**: Change the password immediately after first login!

## Configuration

### Environment Variables

```bash
# Nginx Proxy Manager
NPM_VERSION=2.11.3

# Database
MYSQL_HOST=db
MYSQL_PORT=3306
MYSQL_DATABASE=npm
MYSQL_USER=npm
MYSQL_PASSWORD=change_me_npm_password

# Admin User
ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=change_me_strong_password

# Network
TZ=Asia/Ho_Chi_Minh
```

### Network Ports

| Port | Service | Description |
|------|---------|-------------|
| 80 | HTTP | HTTP server (redirects to HTTPS) |
| 443 | HTTPS | HTTPS server |
| 81 | Admin | Nginx Proxy Manager UI |

## Features

### SSL Certificates

#### Let's Encrypt (Free)

1. Go to **SSL Certificates** > **Add SSL Certificate**
2. Select **Let's Encrypt**
3. Enter domain names
4. Enable **Use a DNS Challenge** (for wildcard certs)
5. Click **Save**

#### Custom Certificate

1. Go to **SSL Certificates** > **Add SSL Certificate**
2. Select **Custom**
3. Upload certificate files:
   - Certificate (CRT)
   - Private Key (KEY)
   - Certificate Chain (optional)
4. Click **Save**

#### Certificate Renewal

Let's Encrypt certificates auto-renew at 60 days. Manual renewal:

1. Go to **SSL Certificates**
2. Click **Renew** on the certificate

### Proxy Hosts

#### Create Proxy Host

1. Go to **Hosts** > **Proxy Hosts** > **Add Proxy Host**
2. **Details** tab:
   - Domain Names: `app.example.com`
   - Scheme: `http`
   - Forward Hostname/IP: `app-container`
   - Forward Port: `8080`
   - Enable **Force SSL**
   - Enable **HTTP/2 Support**
3. **SSL** tab:
   - Select SSL Certificate
   - Enable **HTTP/2 Support**
   - Enable **HSTS Enabled**
   - Enable **HSTS Sub Domains**
4. **Advanced** tab:
   - Custom Nginx Configuration (optional)
5. Click **Save**

#### Configuration Examples

##### Basic Proxy

```
Domain Names: myapp.example.com
Scheme: http
Forward Hostname/IP: myapp
Forward Port: 3000
```

##### SSL with Redirect

```
Domain Names: www.example.com, example.com
Scheme: https
Forward Hostname/IP: backend
Forward Port: 443
SSL Certificate: example.com
Enable "SSL Redirect"
```

##### WebSocket Support

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection "upgrade";
proxy_http_version 1.1;
```

### Access Lists

#### IP Whitelist

1. Go to **Access Lists** > **Create Access List**
2. Enter name: `Office IPs`
3. Add IP addresses:
   ```
   192.168.1.0/24
   10.0.0.1
   ```
4. Set **Allow** to whitelist, **Deny** to blacklist
5. Click **Save**

#### Apply to Proxy Host

1. Edit Proxy Host
2. Go to **Access List** tab
3. Select Access List
4. Click **Save**

### Rate Limiting

In Proxy Host **Advanced** config:

```nginx
limit_req_zone $binary_remote_addr zone=limit:10m rate=10r/s;
limit_req zone=limit burst=20 nodelay;
```

## DNS Configuration

### Cloudflare

1. Enable Cloudflare API key in NPM
2. Select Cloudflare DNS provider
3. NPM auto-creates DNS challenge records

### Manual DNS

For wildcard certificates:

```bash
# Add TXT record manually
# _acme-challenge.example.com 300 IN TXT "xxxxx"
```

## Docker Compose

```yaml
version: '3.8'

services:
  nginx-proxy-manager:
    image: jc21/nginx-proxy-manager:${NPM_VERSION:-2.11.3}
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "81:81"
    environment:
      DB_MYSQL_HOST: ${MYSQL_HOST:-db}
      DB_MYSQL_PORT: ${MYSQL_PORT:-3306}
      DB_MYSQL_DATABASE: ${MYSQL_DATABASE:-npm}
      DB_MYSQL_USER: ${MYSQL_USER:-npm}
      DB_MYSQL_PASSWORD: ${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
    networks:
      - npm_network

  db:
    image: jc21/mariadb:${MARIADB_VERSION:-latest}
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-npm}
      MYSQL_USER: ${MYSQL_USER:-npm}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}
    volumes:
      - ./data/mysql:/var/lib/mysql
    networks:
      - npm_network

networks:
  npm_network:
    name: npm_network
    driver: bridge
```

## Security Best Practices

### 1. Change Default Password

After first login, change the admin password immediately.

### 2. Restrict Admin Access

```nginx
# In Proxy Host for port 81
location / {
    allow 192.168.1.0/24;  # Office IP
    deny all;
    proxy_pass http://localhost:81;
}
```

Or use UFW:

```bash
ufw allow from 192.168.1.0/24 to any port 81
```

### 3. Enable HSTS

In SSL settings:

- HSTS Enabled: Yes
- HSTS Sub Domains: Yes
- Max-Age: 31536000 (1 year)

### 4. SSL/TLS Settings

Use secure ciphers:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
ssl_prefer_server_ciphers off;
```

### 5. Rate Limiting

Protect against DDoS:

```nginx
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req zone=general burst=50 nodelay;
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs nginx-proxy-manager

# Check port conflicts
netstat -tlnp | grep -E '80|443|81'

# Common issue: port already in use
# Stop other services using those ports
```

### SSL Certificate Failed

1. **DNS not propagated**
   ```bash
   # Check DNS
   dig +short example.com
   # Wait for propagation (can take up to 48 hours)
   ```

2. **Port not accessible**
   ```bash
   # Check firewall
   ufw status
   # Ensure 80, 443 are open
   ```

3. **Cloudflare proxy**
   - Disable Cloudflare proxy (grey cloud) for ACME challenge
   - Re-enable after certificate issued

### 502 Bad Gateway

1. **Backend not running**
   ```bash
   docker ps
   docker logs <backend-container>
   ```

2. **Wrong hostname/IP**
   - Verify hostname resolves
   ```bash
   ping <backend-hostname>
   ```

3. **Wrong port**
   - Check backend is listening on correct port
   ```bash
   docker port <backend-container>
   ```

### 504 Gateway Timeout

Increase timeout in **Advanced** config:

```nginx
proxy_connect_timeout 60s;
proxy_send_timeout 60s;
proxy_read_timeout 60s;
```

### Can't Access Admin UI

```bash
# Check if container is running
docker ps | grep nginx-proxy-manager

# Check logs
docker-compose logs --tail=50 nginx-proxy-manager

# Restart container
docker-compose restart nginx-proxy-manager
```

### Password Reset

If you forgot the admin password:

```bash
# Reset to default
docker exec nginx-proxy-manager sh -c "echo 'admin:administrator' > /data/nginx/htpasswd/default"

# Or create new user
docker exec nginx-proxy-manager sh -c "htpasswd -bc /data/nginx/htpasswd/default admin newpassword"
docker restart nginx-proxy-manager
```

## Maintenance

### Update

```bash
# Pull latest image
docker-compose pull

# Restart
docker-compose up -d

# Check logs
docker-compose logs -f
```

### Backup

```bash
# Backup data
tar -czf npm-backup.tar.gz ./data ./letsencrypt

# Restore
tar -xzf npm-backup.tar.gz
```

### Clean Old Certificates

```bash
# Remove expired certs
docker exec nginx-proxy-manager sh -c "find /data -name '*.pem' -mtime +60 -delete"

# Restart
docker restart nginx-proxy-manager
```

## API

Nginx Proxy Manager provides a REST API:

```bash
# Login
curl -X POST http://localhost:81/api/sessions \
  -H "Content-Type: application/json" \
  -d '{" identity":"admin@example.com","secret":"password"}'

# Get proxy hosts
curl http://localhost:81/api/nginx/proxy-hosts \
  -H "Authorization: Bearer <token>"

# Create proxy host
curl -X POST http://localhost:81/api/nginx/proxy-hosts \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"domain_names":["app.example.com"],"scheme":"http","forward_hostname":"app","forward_port":3000}'
```

## Resources

- [Nginx Proxy Manager Docs](https://nginxproxymanager.com/)
- [Nginx Proxy Manager GitHub](https://github.com/NginxProxyManager/nginx-proxy-manager)
- [Community Support](https://community.nginxproxy.net/)
