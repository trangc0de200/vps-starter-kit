# Encryption Notes

## Overview

This document covers encryption best practices for VPS secrets management.

## Encryption Methods

### 1. AES-256-CBC

Symmetric encryption for secrets at rest.

**Pros:**
- Fast and efficient
- Widely supported
- Strong security

**Cons:**
- Key management required
- Same key for encrypt/decrypt

**Usage:**
```bash
# Encrypt
openssl enc -aes-256-cbc -salt -pbkdf2 \
    -in secrets.txt \
    -out secrets.enc

# Decrypt
openssl enc -aes-256-cbc -d -pbkdf2 \
    -in secrets.enc \
    -out secrets.txt
```

### 2. GPG

OpenPGP encryption for secure sharing.

**Pros:**
- Key pair encryption
- Easy key sharing
- Widely supported

**Cons:**
- Larger files
- Key management complexity

**Usage:**
```bash
# Encrypt
gpg --symmetric --cipher-algo AES256 \
    --output secrets.gpg secrets.txt

# Decrypt
gpg --decrypt --output secrets.txt secrets.gpg
```

### 3. SOPS

Mozilla SOPS for encrypted files in Git.

**Pros:**
- Encrypt YAML/JSON directly
- Multiple key management backends
- Git-friendly

**Cons:**
- Additional dependency
- Configuration required

**Key Management:**
- GPG
- AWS KMS
- GCP KMS
- Azure Key Vault
- HashiCorp Vault

**Usage:**
```bash
# Initialize with GPG
sops --generate-keys

# Create encrypted file
sops --encrypt secrets.yaml > secrets.enc.yaml

# Edit encrypted file
sops secrets.enc.yaml

# Decrypt
sops --decrypt secrets.enc.yaml
```

## Key Management

### Key Generation

```bash
# Random key (hex)
openssl rand -hex 32

# Random key (base64)
openssl rand -base64 32

# SSH key
ssh-keygen -t ed25519 -f key.pem

# GPG key
gpg --full-generate-key
```

### Key Storage

| Storage | Use Case | Security |
|---------|----------|----------|
| HSM | Production keys | Highest |
| Vault | Application secrets | High |
| AWS KMS | AWS services | High |
| File (encrypted) | Development | Medium |
| Environment | Containers | Low |

### Key Rotation

- Rotate encryption keys every 90 days
- Re-encrypt data with new key
- Keep old key for decryption
- Document rotation process

## Best Practices

### Do's

1. **Use strong encryption** (AES-256, ChaCha20)
2. **Encrypt at rest** all secrets
3. **Use key derivation** (PBKDF2, Argon2)
4. **Rotate keys** regularly
5. **Store keys separately** from data
6. **Use unique keys** per environment
7. **Audit key access**

### Don'ts

1. Don't commit secrets to Git
2. Don't use weak encryption
3. Don't hardcode keys
4. Don't share keys via email
5. Don't store keys in code
6. Don't use same key for everything
7. Don't ignore encryption warnings

## Password Hashing

For passwords, use hashing, not encryption:

```bash
# bcrypt
htpasswd -nbBC 10 user password

# argon2
echo "password" | argon2 "salt" -t 3 -k 65536 -p 4

# sha512crypt
python3 -c "import crypt; print(crypt.crypt('password', crypt.mksalt(crypt.METHOD_SHA512)))"
```

## TLS/SSL

### Generate Certificate

```bash
# Self-signed
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout key.pem -out cert.pem \
    -subj "/CN=localhost"

# Let's Encrypt
certbot certonly --nginx -d example.com
```

### Certificate Types

| Type | Use Case | Issuer |
|------|----------|--------|
| CA | Signing | Root CA |
| Self-signed | Development | Self |
| Let's Encrypt | Production | Let's Encrypt |
| Commercial | Production | DigiCert, etc. |

## Compliance

### GDPR

- Encrypt personal data
- Key management documented
- Data breach procedures
- Right to be forgotten

### PCI-DSS

- Encryption at rest
- Strong cryptography
- Key rotation
- Access control

### SOC 2

- Encryption controls
- Key management
- Access logging
- Incident response

## Resources

- [OWASP Cryptographic Practices](https://owasp.org/www-project-cheat-sheets/)
- [Mozilla SOPS](https://github.com/mozilla/sops)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [OpenSSL Documentation](https://www.openssl.org/docs/)
