# Security Audit Checklist

Comprehensive security audit checklist for VPS infrastructure.

## Pre-Audit

- [ ] Schedule maintenance window
- [ ] Notify stakeholders
- [ ] Backup configurations
- [ ] Prepare audit tools
- [ ] Document baseline

## 1. System Hardening

### Operating System

- [ ] OS updated (`apt update && apt upgrade`)
- [ ] Unnecessary packages removed
- [ ] Automatic updates enabled
- [ ] Kernel hardened
- [ ] SELinux/AppArmor enabled

### Users and Authentication

- [ ] Root account disabled (PermitRootLogin no)
- [ ] Default admin renamed
- [ ] SSH key-only authentication
- [ ] Strong passwords enforced
- [ ] Password policy configured
- [ ] 2FA enabled for sudo
- [ ] Inactive accounts removed
- [ ] Wheel group limited

### File System

- [ ] /tmp mounted with noexec
- [ ] /var/log secured
- [ ] Important files read-only
- [ ] SUID files reviewed
- [ ] World-writable files found
- [ ] Unowned files found

## 2. Network Security

### Firewall

- [ ] UFW/iptables enabled
- [ ] Default policy DROP
- [ ] Only necessary ports open
- [ ] Stateful tracking enabled
- [ ] Rate limiting configured
- [ ] Fail2Ban enabled
- [ ] Port knocking configured (optional)

### Network Services

- [ ] Unnecessary services disabled
- [ ] DNS secured (DNSSEC)
- [ ] NTP synchronized
- [ ] Network interfaces reviewed
- [ ] IP forwarding disabled
- [ ] ICMP redirects disabled

### SSH Configuration

- [ ] Port changed from 22
- [ ] Protocol 2 only
- [ ] Root login disabled
- [ ] Password auth disabled
- [ ] Empty passwords disabled
- [ ] Strong ciphers
- [ ] Strong key exchange
- [ ] Connection timeout configured
- [ ] Max auth attempts limited
- [ ] Banner configured

## 3. Application Security

### Web Server

- [ ] SSL/TLS configured
- [ ] Strong protocols only
- [ ] Strong ciphers only
- [ ] HSTS enabled
- [ ] Security headers added
- [ ] Directory listing disabled
- [ ] Server tokens hidden

### Databases

- [ ] Root password changed
- [ ] Strong passwords
- [ ] Remote root disabled
- [ ] Unnecessary databases removed
- [ ] SSL connections
- [ ] Query logging
- [ ] Slow query log

### Docker

- [ ] Rootless mode
- [ ] Registry TLS
- [ ] No privileged containers
- [ ] Resource limits
- [ ] Network隔离
- [ ] Log driver configured
- [ ] Content trust enabled

## 4. Monitoring and Logging

### Logging

- [ ] Syslog configured
- [ ] Auth logs secured
- [ ] Log rotation
- [ ] Centralized logging
- [ ] Log monitoring
- [ ] Alerts configured

### Monitoring

- [ ] Uptime monitoring
- [ ] Resource monitoring
- [ ] Security monitoring
- [ ] Network monitoring
- [ ] Alerting configured

### Intrusion Detection

- [ ] Fail2Ban configured
- [ ] RKHunter installed
- [ ] Chkrootkit installed
- [ ] Lynis audit scheduled
- [ ] AIDE configured

## 5. Backup and Recovery

### Backups

- [ ] Automated backups
- [ ] Off-site backup
- [ ] Backup encryption
- [ ] Backup verification
- [ ] Backup retention

### Recovery

- [ ] Recovery plan documented
- [ ] Recovery tested
- [ ] RTO/RPO defined
- [ ] Incident response plan

## 6. Access Control

### Physical Security

- [ ] Server room access
- [ ] Console access
- [ ] Boot password
- [ ] Disk encryption

### Cloud Security (if applicable)

- [ ] IAM configured
- [ ] MFA enabled
- [ ] VPC configured
- [ ] Security groups reviewed
- [ ] CloudTrail enabled

## 7. Compliance

### Data Protection

- [ ] Sensitive data identified
- [ ] Data encrypted at rest
- [ ] Data encrypted in transit
- [ ] PII handling
- [ ] Data retention policy

### Regulations

- [ ] GDPR compliance
- [ ] PCI-DSS (if applicable)
- [ ] HIPAA (if applicable)
- [ ] SOC 2 (if applicable)

## 8. Documentation

### Documentation

- [ ] Architecture diagram
- [ ] Network diagram
- [ ] IP address plan
- [ ] Service catalog
- [ ] Configuration baseline
- [ ] Change log

### Procedures

- [ ] Incident response
- [ ] Change management
- [ ] Backup procedures
- [ ] Recovery procedures
- [ ] Escalation path

## Audit Schedule

| Frequency | Tasks |
|-----------|-------|
| Daily | Log review, Backup check |
| Weekly | Updates, Fail2Ban review |
| Monthly | Full audit, Password rotation |
| Quarterly | Security assessment |
| Annually | Penetration testing |

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| SSH brute force | High | Medium | Fail2Ban, Key auth |
| SQL Injection | Medium | High | WAF, Input validation |
| DDoS | Medium | High | Rate limiting, CDN |
| Data breach | Low | Critical | Encryption, Access control |

## Sign-off

```
Audit Date: _______________
Auditor: _______________
Approved By: _______________
Next Audit: _______________
```
