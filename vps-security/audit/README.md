# Security Audit

Security audit tools and checklists for VPS infrastructure.

## Overview

This module provides:
- Security audit checklist
- Automated audit scripts
- Compliance templates
- Incident response guides

## Audit Checklist

See [audit-checklist.md](audit-checklist.md) for detailed checklist.

### Quick Audit

```bash
# Run basic security checks
cd vps-security/audit
./audit.sh basic

# Full audit
./audit.sh full

# Compliance check
./audit.sh compliance
```

## Audit Categories

### System Security

- [ ] OS updated
- [ ] Unnecessary packages removed
- [ ] Root login disabled
- [ ] SSH key-only authentication
- [ ] Firewall enabled
- [ ] Fail2Ban configured

### Network Security

- [ ] Ports scanned
- [ ] Unnecessary services stopped
- [ ] SSL/TLS configured
- [ ] DNS secure
- [ ] VPN configured

### Application Security

- [ ] Dependencies updated
- [ ] Secrets not in code
- [ ] File permissions correct
- [ ] Logs monitored
- [ ] Backups tested

### Access Control

- [ ] Users reviewed
- [ ] Groups reviewed
- [ ] Sudo access reviewed
- [ ] Passwords rotated
- [ ] 2FA enabled

## Audit Tools

### Lynis

Security auditing tool:

```bash
# Install
apt install lynis

# Run audit
lynis audit system

# Schedule weekly
crontab -e
0 3 * * 0 /usr/bin/lynis audit system --cronjob
```

### RKHunter

Rootkit detection:

```bash
# Install
apt install rkhunter

# Update database
rkhunter --update

# Run scan
rkhunter --checkall

# Schedule
crontab -e
0 4 * * * /usr/bin/rkhunter --checkall --cronjob
```

### Chkrootkit

Rootkit scanner:

```bash
# Install
apt install chkrootkit

# Run scan
chkrootkit

# Schedule
crontab -e
0 5 * * * /usr/sbin/chkrootkit
```

## Automated Audit Script

```bash
#!/bin/bash
# audit.sh - VPS Security Audit Script

set -euo pipefail

echo "========================================"
echo "  VPS Security Audit"
echo "========================================"

# System Info
echo -e "\n[1] System Information"
uname -a
cat /etc/os-release | grep PRETTY_NAME

# Users
echo -e "\n[2] User Accounts"
awk -F: '($3 == 0) {print}' /etc/passwd

# SSH Configuration
echo -e "\n[3] SSH Configuration"
grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication" /etc/ssh/sshd_config

# Firewall
echo -e "\n[4] Firewall Status"
ufw status 2>/dev/null || iptables -L -n 2>/dev/null || echo "No firewall detected"

# Open Ports
echo -e "\n[5] Open Ports"
ss -tlnp

# Failed Logins
echo -e "\n[6] Recent Failed Logins"
lastlog | grep -v Never | tail -10
grep "Failed password" /var/log/auth.log 2>/dev/null | tail -10

# Running Services
echo -e "\n[7] Running Services"
systemctl list-units --type=service --state=running | grep -vE "systemd|ssh|docker" | head -20

# Updates
echo -e "\n[8] Available Updates"
apt list --upgradable 2>/dev/null | tail -10

# Docker Security
echo -e "\n[9] Docker Security"
docker info 2>/dev/null | grep -iE "storage|driver|logging" | head -5

echo -e "\n========================================"
echo "  Audit Complete"
echo "========================================"
```

## Compliance

### CIS Benchmark

Follow CIS benchmarks for:
- Ubuntu Server
- Docker
- Kubernetes

### GDPR Compliance

- Data encryption
- Access logs
- Backup procedures
- Incident response

## Incident Response

### Steps

1. **Detect** - Identify the incident
2. **Contain** - Limit the damage
3. **Eradicate** - Remove the threat
4. **Recover** - Restore systems
5. **Document** - Record everything

### Emergency Contacts

```
Security Team: security@example.com
System Admin: admin@example.com
Escalation: manager@example.com
```

## Files

```
audit/
├── README.md
├── audit-checklist.md
└── audit.sh (to be created)
```
