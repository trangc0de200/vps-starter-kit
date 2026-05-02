# VPS Security Stack

Production-ready security hardening and protection for VPS infrastructure.

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         SECURITY LAYER                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │     WAF      │  │   Fail2Ban    │  │   SSH       │           │
│  │ ModSecurity  │  │  Intrusion   │  │ Hardening   │           │
│  │   + OWASP    │  │ Prevention   │  │             │           │
│  │    Rules     │  │              │  │             │           │
│  └──────┬───────┘  └──────┬───────┘  └──────────────┘           │
│         │                  │                                        │
│  ┌──────┴───────┐  ┌──────┴───────┐                              │
│  │ Rate Limit   │  │ Auto Ban    │                              │
│  │ IP Blacklist │  │ Brute Force │                              │
│  │ SSL/TLS      │  │ Log Monitor │                              │
│  └──────────────┘  └──────────────┘                              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Components

### Web Application Firewall

| Component | Description | Port |
|-----------|-------------|------|
| [ModSecurity](waf/) | WAF engine with OWASP CRS | 8080, 8443 |
| [Nginx](waf/) | Reverse proxy with security headers | 80, 443 |

### Intrusion Prevention

| Component | Description |
|-----------|-------------|
| [Fail2Ban](fail2ban/) | Brute-force protection |
| [Audit](audit/) | Security audit tools |

### SSH Hardening

| Component | Description |
|-----------|-------------|
| [SSH Config](ssh/) | Secure SSH configuration |

## Quick Start

### 1. Configure WAF

```bash
cd vps-security/waf
cp .env.example .env
nano .env
docker-compose up -d
```

### 2. Configure Fail2Ban

```bash
cp fail2ban/jail.local.example /etc/fail2ban/jail.local
systemctl enable fail2ban
systemctl start fail2ban
```

### 3. Harden SSH

```bash
cp ssh/sshd_config.hardened.example /etc/ssh/sshd_config.d/hardening.conf
systemctl restart sshd
```

## Features

### WAF Protection

- **SQL Injection** detection and blocking
- **XSS** protection
- **CSRF** token validation
- **Path Traversal** prevention
- **File Inclusion** protection
- **Rate Limiting** per IP
- **IP Blacklist/Whitelist**
- **OWASP CRS** rules

### Security Headers

- Strict-Transport-Security (HSTS)
- Content-Security-Policy (CSP)
- X-Frame-Options
- X-Content-Type-Options
- Referrer-Policy
- Permissions-Policy

### Fail2Ban

- SSH brute-force protection
- HTTP/HTTPS attack prevention
- Custom jail configurations
- Auto-unban after duration
- Email notifications

### SSH Hardening

- Key-based authentication only
- Disable root login
- Change default port
- Limit login attempts
- Connection timeouts

## Security Checklist

See [audit/audit-checklist.md](audit/audit-checklist.md) for complete security audit.

## Documentation

- [WAF Configuration](waf/README.md)
- [WAF Advanced Config](waf/CONFIG.md)
- [Fail2Ban Setup](fail2ban/README.md)
- [SSH Hardening](ssh/README.md)
- [Security Audit](audit/README.md)

## Port Reference

| Port | Service | Description |
|------|---------|-------------|
| 80 | HTTP | Redirects to HTTPS |
| 443 | HTTPS | WAF protected |
| 8080 | HTTP Alt | WAF without SSL |
| 8443 | HTTPS Alt | WAF with SSL |

## Integration

### With Nginx Proxy Manager

1. Point NPM to WAF backend
2. WAF protects all traffic
3. Clean requests pass to applications

### With Docker

```yaml
services:
  app:
    depends_on:
      - waf
    environment:
      - UPSTREAM=waf:8080
```

## Monitoring

### View Blocked Requests

```bash
# WAF logs
docker-compose -f vps-security/waf logs -f

# Fail2ban status
fail2ban-client status
fail2ban-client status sshd
```

### Real-time Stats

```bash
# ModSecurity audit log
tail -f /var/log/modsec_audit.log

# Nginx error log
tail -f /var/log/nginx/error.log
```

## Best Practices

### Always

1. Keep rules updated
2. Monitor logs regularly
3. Test before deployment
4. Whitelist known IPs
5. Enable logging
6. Review blocked requests

### Never

1. Don't block search engines
2. Don't whitelist too broadly
3. Don't disable all rules
4. Don't ignore alerts
5. Don't use default ports

## Troubleshooting

### Legitimate Requests Blocked

1. Check logs: `grep "Blocked" /var/log/modsec_audit.log`
2. Add to whitelist: `waf/modsecurity.d/whitelist.txt`
3. Reload: `docker-compose -f vps-security/waf exec waf nginx -s reload`

### WAF Not Starting

```bash
# Check logs
docker-compose -f vps-security/waf logs

# Verify ports
netstat -tlnp | grep -E '80|443|8080|8443'

# Check config
docker-compose -f vps-security/waf exec waf nginx -t
```

### Fail2Ban Not Working

```bash
# Check status
fail2ban-client status

# Check logs
tail -f /var/log/fail2ban.log

# Verify regex
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf
```
