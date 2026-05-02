# WAF Configuration Reference

## ModSecurity Directives

### DetectionOnly Mode

Test rules without blocking:

```apache
SecRuleEngine DetectionOnly
```

### Production Mode

Enable blocking:

```apache
SecRuleEngine On
```

## OWASP CRS Configuration

### Paranoia Level

```apache
# Low (1) - Default
SecAction \
    "id:900000,\
    phase:1,\
    pass,\
    t:none,\
    setvar:tx.paranoia_level=1"

# Medium (2)
SecAction \
    "id:900000,\
    phase:1,\
    pass,\
    t:none,\
    setvar:tx.paranoia_level=2"
```

### Anomaly Threshold

```apache
# Critical threshold
SecAction \
    "id:900001,\
    phase:1,\
    pass,\
    t:none,\
    setvar:tx.critical_anomaly_score=5"

# Warning threshold  
SecAction \
    "id:900002,\
    phase:1,\
    pass,\
    t:none,\
    setvar:tx.warning_anomaly_score=4"
```

## Request Limits

### Body Size

```apache
# Maximum request body size
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072
```

### File Upload

```apache
# Maximum file size
SecRequestBodyLimit 10485760

# Allowed file types
SecUploadKeepFiles On
SecUploadDir /var/tmp
```

### Timeout

```apache
# Request timeout
SecRequestReadTimeout Timeout=60
```

## IP Handling

### Blacklist

```apache
# From file
SecRule REMOTE_ADDR "@ipMatchFromFile /etc/modsecurity/blacklist.txt" \
    "id:1001,phase:1,deny,status:403,msg:'IP Blacklisted'"
```

### Whitelist

```apache
# Bypass rules for whitelist
SecRule REMOTE_ADDR "@ipMatchFromFile /etc/modsecurity/whitelist.txt" \
    "id:1002,phase:1,pass,ctl:ruleEngine=Off"
```

## Custom Rules

### Block User-Agent

```apache
SecRule REQUEST_HEADERS:User-Agent "@rx (curl|wget|python|scrapy)" \
    "id:2001,phase:1,deny,status:403,msg:'Blocked User-Agent'"
```

### Block Referer Spam

```apache
SecRule REQUEST_HEADERS:Referer "@rx (porn|gamble|casino)" \
    "id:2002,phase:1,deny,status:403,msg:'Referer spam blocked'"
```

### Block Country

```apache
# Requires GeoIP database
SecRule GEO:COUNTRY_CODE "@streq CN" \
    "id:2003,phase:1,deny,status:403,msg:'Country blocked'"
```

### Rate Limiting

```apache
# Using mod_unique_id
SecAction \
    "id:2004,phase:1,pass,t:none,\
    initcol:ip=%{REMOTE_ADDR},\
    setvar:ip.request_cnt=+1"

SecRule ip:request_cnt "@gt 1000" \
    "id:2005,phase:1,deny,status:429,msg:'Rate limit exceeded'"
```

### Block Admin Abuse

```apache
SecRule ARGS:admin "@contains delete" \
    "id:2006,phase:2,deny,status:403,msg:'Admin action blocked'"

SecRule REQUEST_URI "@beginsWith /wp-admin" \
    "id:2007,phase:1,deny,status:403,msg:'Admin access blocked'"
```

## Logging

### Audit Log

```apache
# Log all transactions
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus "^(?:5|4(?!04))"

# Log location
SecAuditLog /var/log/modsec_audit.log
SecAuditLogParts ABIJDFHZ
```

### Debug Log

```apache
SecDebugLog /var/log/modsec_debug.log
SecDebugLogLevel 0
```

## Headers

### Security Headers

```apache
# HSTS
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

# X-Frame
Header always set X-Frame-Options "SAMEORIGIN"

# X-Content-Type
Header always set X-Content-Type-Options "nosniff"

# CSP
Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'"
```

## Exclusions

### Disable Rules for Path

```apache
SecRule REQUEST_URI "@beginsWith /api/health" \
    "id:3001,phase:1,pass,ctl:ruleRemoveById=941100-942999"
```

### Disable Rules for Parameter

```apache
SecRuleUpdateTargetById 942100 "!ARGS:search_query"
```

### Disable Rules for IP

```apache
SecRule REMOTE_ADDR "@ipMatch 192.168.1.0/24" \
    "id:3002,phase:1,pass,ctl:ruleEngine=Off"
```

## Response Headers

### Add Security Headers

```apache
# Remove server header
Header unset Server
Header always set Server "SecurityWAF"

# Remove powered-by
Header unset X-Powered-By
Header always set X-Powered-By "SecurityWAF"
```

## Performance

### Compression

```apache
# Enable GZIP
SetOutputFilter DEFLATE
```

### Caching

```apache
# Cache static assets
<LocationMatch "\.(jpg|png|gif|css|js)$">
    ExpiresActive On
    ExpiresDefault "access plus 1 week"
</LocationMatch>
```

## Kubernetes Integration

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: modsecurity-config
data:
  custom-rules.conf: |
    SecRule REQUEST_URI ...
```

### Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/use-regex: "true"
```
