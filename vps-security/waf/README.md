# ModSecurity WAF

Web Application Firewall with ModSecurity and OWASP Core Rule Set.

## Overview

ModSecurity provides:
- Real-time request monitoring
- Attack detection and prevention
- Custom rule creation
- Logging and audit trails

## Quick Start

```bash
cd vps-security/waf
cp .env.example .env
docker-compose up -d
```

## Ports

| Port | Service | Description |
|------|---------|-------------|
| 80 | HTTP | Redirects to HTTPS |
| 443 | HTTPS | WAF protected |
| 8080 | HTTP Alt | WAF without SSL |
| 8443 | HTTPS Alt | WAF with SSL |

## Features

### OWASP Core Rule Set

Pre-configured protection against:
- SQL Injection (SQLi)
- Cross-Site Scripting (XSS)
- Local File Inclusion (LFI)
- Remote File Inclusion (RFI)
- PHP Injection
- HTTP Protocol Violations
- Real-time Blacklist

### Security Headers

| Header | Value |
|--------|-------|
| Strict-Transport-Security | max-age=31536000; includeSubDomains |
| X-Frame-Options | SAMEORIGIN |
| X-Content-Type-Options | nosniff |
| X-XSS-Protection | 1; mode=block |
| Referrer-Policy | strict-origin-when-cross-origin |
| Content-Security-Policy | default-src 'self' |

### Rate Limiting

- 100 requests per minute per IP
- 1000 requests per hour per IP
- Burst allowance: 200 requests

## Configuration

### Environment Variables

```bash
# Network
WAF_HTTP_PORT=80
WAF_HTTPS_PORT=443
WAF_HTTP_ALT_PORT=8080
WAF_HTTPS_ALT_PORT=8443

# SSL
SSL_CERT_PATH=/path/to/cert.pem
SSL_KEY_PATH=/path/to/key.pem

# Rules
ENABLE_OWASP_CRS=true
PARANOIA_LEVEL=1
ANOMALY_THRESHOLD=5

# Logging
LOG_LEVEL=info
ENABLE_AUDIT_LOG=true
```

### Blacklist IPs

Edit `modsecurity.d/blacklist.txt`:

```
# One IP per line
1.2.3.4
5.6.7.8
```

### Whitelist IPs

Edit `modsecurity.d/whitelist.txt`:

```
# IPs that bypass WAF rules
127.0.0.1
192.168.1.0/24
```

### Custom Rules

Edit `modsecurity.d/custom-rules.conf`:

```apache
# Block specific URL
SecRule REQUEST_URI "@contains /admin/delete" \
    "id:1001,phase:1,deny,status:403,msg:'Admin action blocked'"

# Block specific User-Agent
SecRule REQUEST_HEADERS:User-Agent "@contains malicious-bot" \
    "id:1002,phase:1,deny,status:403,msg:'Malicious bot blocked'"
```

## Proxy to Backend

### Docker Container

```yaml
# Point to your application
BACKEND_URL=http://app:3000
```

### Kubernetes

```yaml
# In your service
backend: http://waf:8080
```

## Log Analysis

### View Blocked Requests

```bash
# Real-time logs
docker-compose logs -f

# Search for blocked
grep "blocked" /var/log/modsec_audit.log

# Search by rule ID
grep "985550" /var/log/modsec_audit.log
```

### Common Rule IDs

| ID | Description |
|----|-------------|
| 920350 | Request missing Host header |
| 920360 | Host header is IP address |
| 942100 | SQL Injection detected |
| 941100 | XSS detected |
| 930100 | Path traversal detected |

## Paranoia Levels

| Level | Description |
|-------|-------------|
| 1 | Basic rules (default) |
| 2 | Extended rules |
| 3 | Strict rules |
| 4 | Extreme rules |

## Management

### Reload Rules

```bash
docker-compose exec waf nginx -s reload
```

### Update Rules

```bash
docker-compose pull
docker-compose up -d
```

### View Statistics

```bash
# Nginx status
curl http://localhost:8080/nginx_status

# ModSecurity status (custom endpoint)
curl http://localhost:8080/modsec-status
```

## SSL/TLS

### Self-Signed Certificate

```bash
# Generate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout.key -out.crt \
    -subj "/CN=localhost"
```

### Let's Encrypt

```bash
# Use Nginx Proxy Manager
# Or certbot
certbot certonly --nginx -d example.com
```

## Troubleshooting

### 403 Forbidden Errors

1. Check if IP is blacklisted
2. Check custom rules
3. Check anomaly score
4. Review logs

### High False Positives

1. Lower anomaly threshold
2. Reduce paranoia level
3. Add exceptions to whitelist
4. Review custom rules

### Performance Issues

1. Disable unnecessary rules
2. Reduce log verbosity
3. Use caching
4. Increase worker processes

## Files

```
waf/
├── README.md
├── CONFIG.md
├── docker-compose.yml
├── .env.example
├── nginx.conf
├── waf.sh
├── conf.d/
│   ├── 00-rate-limit.conf
│   ├── 01-security-headers.conf
│   └── 99-server.conf
├── modsecurity.d/
│   ├── custom-rules.conf
│   ├── blacklist.txt
│   └── whitelist.txt
└── ssl/
    └── README.md
```
