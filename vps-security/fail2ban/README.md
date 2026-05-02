# Fail2Ban

Intrusion prevention for SSH, HTTP, and other services.

## Overview

Fail2Ban monitors log files and bans IPs that show malicious signs:
- Too many password failures
- Exploiting vulnerabilities
- Manual ban requests

## Quick Start

### Installation

```bash
# Ubuntu/Debian
apt install fail2ban

# CentOS/RHEL
yum install epel-release
yum install fail2ban
```

### Configuration

```bash
# Copy default config
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

# Start service
systemctl enable fail2ban
systemctl start fail2ban
```

## Jails

### Pre-configured Jails

| Jail | Description | Port |
|------|-------------|------|
| sshd | SSH brute-force | 22 |
| apache-auth | Apache auth | 80, 443 |
| nginx-http-auth | Nginx auth | 80, 443 |
| nginx-noscript | Nginx no script | 80, 443 |
| nginx-badrequests | Bad requests | 80, 443 |
| nginx-proxy | Nginx proxy | 80, 443 |
| mysql-auth | MySQL auth | 3306 |
| postfix | Postfix | 25, 587 |

### Recommended Jails

```ini
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600

[nginx-http-auth]
enabled = true
port = http,https
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 5
bantime = 3600

[nginx-badrequests]
enabled = true
port = http,https
filter = nginx-badrequests
logpath = /var/log/nginx/error.log
maxretry = 10
bantime = 7200
```

## Configuration

### Basic Settings

```ini
[DEFAULT]
# Ban time in seconds (1 hour)
bantime = 3600

# Time window in seconds (10 minutes)
findtime = 600

# Max attempts before ban
maxretry = 5

# Email notification
destemail = admin@example.com
sender = fail2ban@example.com
mta = sendmail

# Action
action = %(action_mwl)s
```

### Actions

```ini
# Ban IP only
action = %(action)s

# Ban and notify
action = %(action_mwl)s

# Ban, notify with whois
action = %(action_xarf)s
```

## Custom Jails

### WordPress Login

```ini
[wordpress]
enabled = true
port = http,https
filter = wordpress
logpath = /var/www/*/logs/access.log
maxretry = 5
bantime = 3600
findtime = 600
```

Create filter `/etc/fail2ban/filter.d/wordpress.conf`:

```ini
[Definition]
failregex = ^<HOST> - .* /wp-login.php HTTP/1.1"
ignoreregex =
```

### Admin Panel

```ini
[admin-panel]
enabled = true
port = http,https
filter = admin-panel
logpath = /var/log/nginx/access.log
maxretry = 3
bantime = 86400
findtime = 3600
```

Create filter `/etc/fail2ban/filter.d/admin-panel.conf`:

```ini
[Definition]
failregex = ^<HOST> - .* /admin/.* HTTP/1.1" 401
failregex = ^<HOST> - .* /wp-admin/.* HTTP/1.1" 401
failregex = ^<HOST> - .* /administrator/.* HTTP/1.1" 401
ignoreregex =
```

### API Endpoints

```ini
[api-abuse]
enabled = true
port = http,https
filter = api-abuse
logpath = /var/log/nginx/api.log
maxretry = 100
bantime = 600
findtime = 60
```

## Commands

### Status

```bash
# Overall status
fail2ban-client status

# Specific jail status
fail2ban-client status sshd
fail2ban-client status nginx-http-auth
```

### Management

```bash
# Ban IP
fail2ban-client set sshd banip 1.2.3.4

# Unban IP
fail2ban-client set sshd unbanip 1.2.3.4

# Add to ignore list
fail2ban-client set sshd addignoreip 192.168.1.0/24

# Remove from ignore list
fail2ban-client set sshd delignoreip 192.168.1.0/24
```

### Reload

```bash
# Reload configuration
fail2ban-client reload

# Reload specific jail
fail2ban-client reload sshd
```

## Monitoring

### Log File

```bash
# View fail2ban logs
tail -f /var/log/fail2ban.log

# Search for bans
grep "Ban" /var/log/fail2ban.log

# Search for unbans
grep "Unban" /var/log/fail2ban.log
```

### Statistics

```bash
# Count banned IPs per jail
cat /var/log/fail2ban.log | grep "Ban" | wc -l

# Most banned IPs
grep "Ban" /var/log/fail2ban.log | awk '{print $NF}' | sort | uniq -c | sort -rn | head -10
```

## Troubleshooting

### Jail Not Working

```bash
# Check if jail is enabled
fail2ban-client status

# Check regex
fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf

# Check log path
ls -la /var/log/auth.log
```

### Too Many False Positives

```bash
# Increase maxretry
fail2ban-client set sshd maxretry 5

# Add to ignore list
fail2ban-client set sshd addignoreip 192.168.1.0/24
```

### Email Not Sending

```bash
# Check MTA
systemctl status postfix

# Test email
echo "Test" | mail -s "Fail2Ban Test" admin@example.com
```

## Integration

### With UFW

```bash
# Install ufw support
action = %(banaction)s[name=%(__name__)s,tport="%(port)s", protocol="tcp", chain="forward"]
action = ufw[name=%(__name__)s]
```

### With IPTables

```bash
# Default action
action = %(action_)s

# Only iptables
banaction = iptables-multiport
```

## Files

```
/etc/fail2ban/
├── jail.conf          # Default configuration
├── jail.local         # Your overrides
├── filter.d/
│   ├── sshd.conf
│   ├── apache-auth.conf
│   └── nginx-http-auth.conf
└── action.d/
    ├── iptables.conf
    ├── ufw.conf
    └── sendmail.conf
```

## Performance

### Large Ban List

```bash
# Check iptables rules
iptables -L f2b-sshd -n --line-numbers

# Clear all bans for jail
fail2ban-client get sshd banlist | xargs -I {} fail2ban-client set sshd unbanip {}
```

## Security Tips

1. **Whitelist your IP** before enabling
2. **Start with DetectionOnly** mode
3. **Monitor logs** for false positives
4. **Adjust thresholds** based on traffic
5. **Use email notifications** for critical bans
