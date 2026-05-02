# SSH Hardening

Secure SSH configuration for production servers.

## Overview

SSH hardening includes:
- Key-based authentication only
- Disable root login
- Change default port
- Limit login attempts
- Connection timeouts
- Two-factor authentication

## Quick Start

### 1. Backup Current Config

```bash
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

### 2. Apply Hardened Config

```bash
cp ssh/sshd_config.hardened.example /etc/ssh/sshd_config.d/hardening.conf
systemctl restart sshd
```

### 3. Test Before Disconnecting

**IMPORTANT**: Keep current session open and test new connection in another terminal.

```bash
# Test connection
ssh -p <new_port> user@server

# If successful, your hardened config works
```

## Configuration

### Hardened sshd_config

```ssh-config
# ===========================================
# SSH Hardening Configuration
# ===========================================

# Disable root login
PermitRootLogin no

# Change default port
Port 2222

# Disable password authentication
PasswordAuthentication no
PermitEmptyPasswords no

# Use only strong ciphers
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr

# Use only strong key exchange
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512

# Use only strong MACs
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Use only strong host key algorithms
HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com

# Disable unused authentication methods
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
HostbasedAuthentication no
IgnoreRhosts yes

# Connection settings
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive yes

# Login grace time
LoginGraceTime 60

# Max auth attempts
MaxAuthTries 3
MaxSessions 10

# Disable X11 forwarding
X11Forwarding no

# Disable agent forwarding
AllowAgentForwarding no

# Disable tunnel
PermitTunnel no

# Disable .rhosts
IgnoreUserKnownHosts yes

# Enable PAM
UsePAM yes

# Print MOTD
PrintMotd yes

# Print last login
PrintLastLog yes

# Subsystem
Subsystem sftp /usr/lib/openssh/sftp-server -f INFO -l VERBOSE

# Allow specific users/groups
AllowUsers deploy admin
AllowGroups sshusers
```

## Security Features

### Key-Based Authentication

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy key to server
ssh-copy-id -p 2222 user@server

# Or manually
cat ~/.ssh/id_ed25519.pub | ssh -p 2222 user@server "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### Two-Factor Authentication

```bash
# Install Google Authenticator
apt install libpam-google-authenticator

# Configure for user
su - username
google-authenticator

# Edit sshd_config
echo "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config.d/hardening.conf

# Edit PAM
echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd
```

### Fail2Ban Integration

```bash
# Update Fail2Ban config for new port
cat >> /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = 2222
maxretry = 3
bantime = 3600
EOF

systemctl restart fail2ban
```

## Users and Groups

### Create SSH Group

```bash
# Create group
groupadd sshusers

# Add users to group
usermod -aG sshusers username
usermod -aG sshusers deploy
```

### Restrict to Group

```ssh-config
AllowGroups sshusers
```

## Connection Examples

### Standard Connection

```bash
ssh -p 2222 user@server
```

### With Key File

```bash
ssh -p 2222 -i ~/.ssh/id_ed25519 user@server
```

### With Agent Forwarding

```bash
ssh -p 2222 -A user@server
```

### SCP File Transfer

```bash
scp -P 2222 file.txt user@server:/path/
```

## Troubleshooting

### Connection Refused

```bash
# Check SSH is running
systemctl status sshd

# Check port
netstat -tlnp | grep sshd

# Check firewall
ufw status
```

### Key Authentication Failed

```bash
# Check key permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Check ownership
chown -R user:user ~/.ssh
```

### Locked Out

1. Access server via console/VNC
2. Check sshd logs: `journalctl -u sshd`
3. Revert changes: `mv /etc/ssh/sshd_config.backup /etc/ssh/sshd_config`
4. Restart: `systemctl restart sshd`

## Firewall Rules

### UFW

```bash
# Allow SSH on new port
ufw allow 2222/tcp

# Deny old port
ufw deny 22/tcp

# Enable UFW
ufw enable
```

### IPTables

```bash
# Allow SSH new port
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT

# Allow established connections
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

## Audit

### Check Current Security

```bash
# Check SSH version
ssh -V

# Check active sessions
who

# Check failed logins
lastlog | grep root
grep "Failed password" /var/log/auth.log

# Check active connections
ss -tn | grep ssh
```

## Files

```
ssh/
├── README.md
├── sshd_config.hardened.example
└── sshd_config.d/
    └── hardening.conf
```

## Best Practices

1. **Always backup** before changing config
2. **Test in another terminal** before closing current session
3. **Use strong keys** (ed25519 or RSA 4096)
4. **Enable 2FA** for additional security
5. **Monitor logs** for failed attempts
6. **Use fail2ban** to block brute force
7. **Keep port secret** (don't use 22)
8. **Limit users** with AllowUsers/AllowGroups
