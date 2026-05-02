# VPS Secrets Management

Secure secrets management for VPS infrastructure with encryption, rotation, and multi-provider support.

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                       SECRETS MANAGEMENT                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Generate   │  │   Encrypt   │  │   Store     │           │
│  │   Secrets    │  │   Secrets   │  │   Secrets   │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                  │                  │                      │
│         └──────────────────┴──────────────────┘                      │
│                            │                                         │
│  ┌────────────────────────┴────────────────────────┐               │
│  │                                                  │               │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐       │               │
│  │  │ Vault   │  │  SOPS   │  │ Docker  │       │               │
│  │  │         │  │         │  │ Secrets │       │               │
│  │  └─────────┘  └─────────┘  └─────────┘       │               │
│  └──────────────────────────────────────────────────┘               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Features

- **Secret Generation**: Secure random passwords, API keys, tokens
- **Encryption**: AES-256 encryption at rest
- **Multi-Provider**: HashiCorp Vault, SOPS, Docker Secrets
- **Rotation**: Automated secret rotation
- **Audit**: Full audit trail
- **Templates**: Pre-configured templates

## Quick Start

### 1. Generate Secrets

```bash
# Generate random password
./scripts/generate_secret.sh 32

# Generate API key
./scripts/generate_secret.sh 64

# Generate JWT secret
./scripts/generate_secret.sh 64
```

### 2. Encrypt Secrets

```bash
# Encrypt with password
./scripts/encrypt.sh --input secrets.txt --output secrets.enc --password

# Encrypt with key file
./scripts/encrypt.sh --input secrets.txt --output secrets.enc --keyfile key.pem
```

### 3. Use in Docker

```bash
# With Docker Swarm
echo "my_secret" | docker secret create my_secret -

# In compose
echo "${SECRET}" | docker secret create app_secret -
```

## Directory Structure

```
vps-secrets/
├── README.md
├── scripts/
│   ├── generate_secret.sh      # Generate secrets
│   ├── encrypt.sh             # Encrypt secrets
│   ├── decrypt.sh             # Decrypt secrets
│   ├── rotate.sh              # Rotate secrets
│   ├── vault.sh               # Vault management
│   └── audit.sh               # Audit secrets
├── templates/
│   ├── env.production.example # Production template
│   ├── docker-secrets.yml    # Docker secrets
│   ├── vault-config.hcl      # Vault config
│   └── encryption_notes.md   # Encryption guide
└── keys/
    └── .gitignore            # Don't commit keys
```

## Secret Types

| Type | Length | Use Case |
|------|--------|----------|
| Password | 32-64 | Database, users |
| API Key | 32-64 | External services |
| JWT Secret | 64-128 | Authentication |
| SSH Key | 4096 | SSH access |
| TLS Cert | - | HTTPS |
| Encryption Key | 32-64 | Data encryption |

## Generation Examples

### Passwords

```bash
# Simple password
./scripts/generate_secret.sh 16

# Complex password
./scripts/generate_secret.sh 32

# High security (mix of all)
./scripts/generate_secret.sh 64

# Pronounceable password
./scripts/generate_secret.sh --pronounceable 3

# UUID
./scripts/generate_secret.sh --uuid
```

### API Keys

```bash
# AWS-style key
./scripts/generate_secret.sh --aws-style

# Generic API key
./scripts/generate_secret.sh --api-key 32

# HMAC key
./scripts/generate_secret.sh --hmac 32
```

### Certificates

```bash
# Generate CA
./scripts/generate_certs.sh --ca

# Generate server cert
./scripts/generate_certs.sh --server --domain example.com

# Generate client cert
./scripts/generate_certs.sh --client --name "client-name"
```

## Encryption

### SOPS (Recommended)

```bash
# Install
brew install sops
# or
pip install sops

# Initialize (first time)
sops --generate-keys

# Edit secrets
sops secrets.yaml

# Encrypt
sops --encrypt secrets.yaml > secrets.enc.yaml
```

### Manual Encryption

```bash
# Encrypt with openssl
openssl enc -aes-256-cbc -salt -pbkdf2 \
    -in secrets.txt \
    -out secrets.enc

# Decrypt
openssl enc -aes-256-cbc -d -pbkdf2 \
    -in secrets.enc \
    -out secrets.txt
```

## Docker Secrets

### Create Secret

```bash
# From file
docker secret create db_password secrets/db_password.txt

# From stdin
echo "secret_value" | docker secret create app_key -

# From docker-compose
echo "${DB_PASSWORD}" | docker secret create db_password -
```

### Use in Services

```yaml
# docker-compose.yml
version: "3.8"

services:
  app:
    image: myapp
    secrets:
      - db_password
      - api_key
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    file: secrets/db_password.txt
  api_key:
    external: true
```

### Swarm Secrets

```bash
# Deploy stack
docker stack deploy -c docker-compose.yml myapp

# List secrets
docker secret ls

# Inspect secret
docker secret inspect db_password

# Remove secret
docker secret rm db_password
```

## HashiCorp Vault

### Quick Start

```bash
# Start Vault dev server
vault server -dev

# Set environment
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN="your-token"

# Enable secrets engine
vault secrets enable -path=secret kv-v2

# Store secret
vault kv put secret/myapp/database password="db_password"

# Read secret
vault kv get secret/myapp/database
```

### Scripts

```bash
# Initialize Vault
./scripts/vault.sh init

# Add secret
./scripts/vault.sh put myapp/db password="secret"

# Get secret
./scripts/vault.sh get myapp/db

# Rotate secret
./scripts/vault.sh rotate myapp/db
```

## Secret Rotation

### Automatic Rotation

```bash
# Setup cron for rotation
crontab -e

# Rotate weekly
0 0 * * 0 cd /opt/vps-secrets && ./scripts/rotate.sh --all

# Rotate specific
0 0 * * 0 cd /opt/vps-secrets && ./scripts/rotate.sh --secret db_password
```

### Manual Rotation

```bash
# Generate new secret
NEW_PASS=$(./scripts/generate_secret.sh 32)

# Update in Vault
vault kv put secret/myapp/database password="${NEW_PASS}"

# Deploy new version
./scripts/deploy.sh --secret db_password
```

## Best Practices

### Secret Management

1. **Never commit secrets** to version control
2. **Use encryption** for secrets at rest
3. **Rotate regularly** (30-90 days)
4. **Use different secrets** for each environment
5. **Audit access** regularly
6. **Use secret managers** (Vault, AWS Secrets Manager)

### Secret Storage

| Storage | Use Case |
|---------|----------|
| HashiCorp Vault | Production, enterprise |
| Docker Secrets | Docker Swarm |
| SOPS + GPG | Git-encrypted |
| AWS Secrets Manager | AWS infrastructure |
| Azure Key Vault | Azure infrastructure |
| GCP Secret Manager | GCP infrastructure |

### Access Control

```bash
# Limit access
chmod 600 secrets/*
chown root:secrets secrets/*

# Audit access
./scripts/audit.sh --report
```

## Environment Variables

### Using .env

```bash
# Load secrets
export $(cat .env | grep -v '^#' | xargs)

# In scripts
source .env
```

### Using Docker

```yaml
environment:
  - DB_PASSWORD=${DB_PASSWORD}
  - API_KEY=${API_KEY}
```

## Templates

### Production Environment

```bash
# Copy template
cp templates/env.production.example .env.production

# Edit with real values
nano .env.production

# Encrypt for deployment
./scripts/encrypt.sh --input .env.production --output .env.production.enc
```

### Database

```yaml
DB_HOST=localhost
DB_PORT=5432
DB_NAME=appdb
DB_USER=appuser
DB_PASSWORD=<generate>
DB_SSL_MODE=require
```

### Application

```yaml
APP_SECRET_KEY=<generate 64>
APP_DEBUG=false
APP_ENV=production
JWT_SECRET=<generate 64>
SESSION_LIFETIME=3600
```

## Troubleshooting

### Permission Denied

```bash
# Fix permissions
chmod 600 secrets/*
ls -la secrets/
```

### Decryption Failed

```bash
# Check key
cat keys/private.key

# Verify key matches
openssl rsa -in keys/private.key -pubout
```

### Vault Unavailable

```bash
# Check status
vault status

# Check logs
journalctl -u vault -f

# Restart
systemctl restart vault
```

## Security

### Audit Trail

```bash
# View access logs
./scripts/audit.sh --logs

# Export audit report
./scripts/audit.sh --report --output audit.csv

# Check for vulnerabilities
./scripts/audit.sh --check
```

### Compliance

- [ ] Secrets encrypted at rest
- [ ] Access logged
- [ ] Rotation policy enforced
- [ ] No hardcoded secrets
- [ ] Secrets in .gitignore

## Documentation

- [Encryption Notes](templates/ENCRYPTION_NOTES.md)
- [Production Template](templates/env.production.example)
- [Docker Secrets](templates/docker-secrets.yml)
- [Vault Config](templates/vault-config.hcl)
