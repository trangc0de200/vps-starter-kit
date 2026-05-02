# 🚀 VPS Starter Kit

<!-- Badges -->
![Version](https://img.shields.io/badge/version-8.0.0-blue)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-orange)
![Docker](https://img.shields.io/badge/Docker-Ready-green)
![License](https://img.shields.io/badge/License-MIT-lightgrey)
![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen)

---

> A production-ready VPS platform template for Ubuntu 24.04 built with Docker, security hardening, monitoring, and GitHub Actions CI/CD.

Transform your fresh VPS into a structured, reusable platform with reverse proxy, HTTPS, databases, caching, application deployment, backup workflows, and comprehensive monitoring.

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Platform Components](#-platform-components)
- [Documentation](#-documentation)
- [CLI Reference](#-cli-reference)
- [Configuration](#-configuration)
- [Contributing](#-contributing)
- [License](#-license)

---

## ✨ Features

### Infrastructure
- **Docker Engine** with Docker Compose plugin
- **UFW Firewall** with sensible defaults
- **Fail2Ban** for brute-force protection
- **Deploy User** with sudo and Docker access

### Databases & Cache
- **PostgreSQL** with backups
- **MySQL/MariaDB** with backups
- **Redis** with persistence
- **SQL Server** (optional)

### Application Delivery
- **Generic App Template** with Docker
- **Environment-aware Deploy Scripts**
- **Health Checks** & **Rollback** support
- **Migration Hooks**
- **CI/CD-ready** layout

### Security
- **SSH Hardening** templates
- **WAF** with ModSecurity + OWASP CRS
- **Fail2Ban** jail templates
- **Security Audit** scripts
- **Port Review** helpers

### Monitoring
- **Netdata** for real-time monitoring
- **Uptime Kuma** for uptime tracking
- **Prometheus + Grafana** stack
- **SSL Expiration** monitoring
- **Disk & Container** checks

### Platform Tools
- **vps-cli** - Central CLI tool
- **Service Registry** - Track deployed services
- **Config Validation** - Check configuration
- **Backup Verification** - Verify backup integrity

---

## 🚀 Quick Start

### Prerequisites

- Ubuntu 24.04 LTS (or 22.04 LTS)
- Fresh VPS or VM
- Root or sudo access
- Git

### One-Line Install

```bash
git clone https://github.com/yourusername/vps-starter-kit.git
cd vps-starter-kit
chmod +x install.sh vps-cli
sudo ./install.sh
```

### Custom Installation

```bash
sudo BOOTSTRAP_USER=deployer \
     VPS_ROOT=/opt/vps \
     INSTALL_NPM=yes \
     AUTO_START_NPM=yes \
     ENABLE_UFW=yes \
     ENABLE_FAIL2BAN=yes \
     TZ_VALUE=Asia/Ho_Chi_Minh \
     ./install.sh
```

### After Installation

```bash
# Login as deploy user
sudo su - deployer

# Check platform status
cd /opt/vps && ./vps-cli status

# Start services
cd /opt/vps/vps-infra/nginx-proxy-manager && docker compose up -d

# Access Nginx Proxy Manager
# URL: http://your-vps-ip:81
# Default: admin@example.com / changeme
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         VPS STARTER KIT                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     SECURITY LAYER                            │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │  │
│  │  │   WAF   │  │Fail2Ban│  │   SSH   │  │  Audit  │       │  │
│  │  │ModSec   │  │        │  │Hardening│  │         │       │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                    INFRASTRUCTURE LAYER                      │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │  │
│  │  │   NPM   │  │  Nginx  │  │  Redis  │  │ Network │       │  │
│  │  │ Proxy   │  │  Proxy  │  │  Cache  │  │ Segments│       │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                      DATA LAYER                              │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │  │
│  │  │Postgres │  │  MySQL  │  │  Redis  │  │Backups  │       │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                   MONITORING LAYER                            │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │  │
│  │  │Netdata  │  │Prometheus│ │ Grafana │  │  Uptime │       │  │
│  │  │         │  │         │  │         │  │  Kuma   │       │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                     PLATFORM LAYER                            │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐       │  │
│  │  │vps-cli  │  │Registry │  │ Deploy  │  │ Secrets │       │  │
│  │  │         │  │         │  │ Scripts │  │         │       │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘       │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📦 Platform Components

### Core Directories

| Directory | Description |
|-----------|-------------|
| `vps-app/` | Generic application template |
| `vps-db/` | Database containers (PostgreSQL, MySQL, Redis) |
| `vps-infra/` | Infrastructure (Nginx Proxy Manager, shared scripts) |
| `vps-monitoring/` | Monitoring stack (Netdata, Prometheus, Grafana) |
| `vps-security/` | Security hardening (WAF, Fail2Ban, SSH) |
| `vps-secrets/` | Secrets management templates |
| `vps-alerting/` | Alert configurations |
| `vps-platform/` | Platform automation scripts |
| `vps-vpn/` | WireGuard VPN server |
| `plugins/` | Optional plugins (MinIO, Kafka, Elasticsearch) |
| `docs/` | Documentation |
| `config/` | Platform configuration |

### Service Ports

| Service | Port | Description |
|---------|------|-------------|
| HTTP | 80 | HTTP traffic |
| HTTPS | 443 | HTTPS traffic |
| NPM Admin | 81 | Nginx Proxy Manager UI |
| WireGuard | 51820 | VPN |
| WireGuard UI | 51821 | VPN Web UI |

---

## 📚 Documentation

### Getting Started
- [Quick Start Guide](docs/OPERATIONS.md)
- [First-Time Setup](docs/OPERATIONS.md#first-time-setup)

### Security
- [Security Hardening](vps-security/README.md)
- [SSH Configuration](vps-security/ssh/README.md)
- [WAF Setup](vps-security/waf/README.md)

### Databases
- [PostgreSQL Setup](vps-db/postgres/README.md)
- [MySQL Setup](vps-db/mysql/README.md)
- [Redis Setup](vps-db/redis/README.md)

### Monitoring
- [Monitoring Guide](docs/MONITORING.md)
- [Netdata](vps-monitoring/netdata/README.md)
- [Prometheus + Grafana](vps-monitoring/prometheus-grafana/README.md)

### Operations
- [Backup & Restore](docs/BACKUP_AND_RESTORE.md)
- [Disaster Recovery](docs/DISASTER_RECOVERY.md)
- [CI/CD Setup](docs/CICD_V3.md)

### VPN
- [WireGuard Setup](vps-vpn/README.md)
- [VPN Configuration](vps-vpn/CONFIG.md)
- [Client Setup](vps-vpn/CLIENTS.md)

---

## 💻 CLI Reference

### vps-cli Commands

```bash
# Status & Info
./vps-cli status              # Show platform status
./vps-cli show-config         # Display configuration
./vps-cli validate-config     # Validate config files
./vps-cli list-services       # List all services

# Health Checks
./vps-cli check-containers    # Check container health
./vps-cli check-disk          # Check disk usage
./vps-cli check-endpoints     # Check HTTP endpoints
./vps-cli check-ssl           # Check SSL expiration

# Backup & Recovery
./vps-cli backup-all          # Run all backups
./vps-cli verify-backups      # Verify backup integrity

# Maintenance
./vps-cli cleanup             # Clean up old containers/images
./vps-cli audit-security      # Run security audit
```

### Helper Scripts

```bash
# Application Management
/opt/vps/scripts/create-app.sh              # Create new application
/opt/vps/scripts/register-project.sh        # Register project
/opt/vps/scripts/register-service.sh        # Register service

# Database
/opt/vps/scripts/backup-db.sh               # Backup databases
/opt/vps/scripts/restore-db.sh              # Restore database

# Monitoring
/opt/vps/scripts/check-ssl.sh               # Check SSL certificates
/opt/vps/scripts/check-endpoints.sh        # Check endpoints
```

---

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `BOOTSTRAP_USER` | `deployer` | Deploy user name |
| `VPS_ROOT` | `/opt/vps` | Platform root directory |
| `INSTALL_NPM` | `yes` | Install Nginx Proxy Manager |
| `AUTO_START_NPM` | `yes` | Start NPM after install |
| `ENABLE_UFW` | `yes` | Enable UFW firewall |
| `ENABLE_FAIL2BAN` | `yes` | Enable Fail2Ban |
| `TZ_VALUE` | `UTC` | Timezone |
| `PROXY_NETWORK` | `proxy_network` | Docker proxy network |
| `DB_NETWORK` | `db_network` | Docker database network |

### Platform Configuration

```bash
# Edit platform config
nano /opt/vps/config/platform.yml

# View current config
./vps-cli show-config
```

---

## 🔧 Usage Examples

### Deploy New Application

```bash
# 1. Create application from template
cd /opt/vps
./scripts/create-app.sh --name myapp --path /opt/myapp

# 2. Configure environment
cd /opt/myapp
cp .env.production.example .env
nano .env

# 3. Deploy
./scripts/deploy.sh --env production --backup

# 4. Access via Nginx Proxy Manager
# Add proxy host pointing to myapp:3000
```

### Database Backup

```bash
# Backup all databases
cd /opt/vps
./scripts/backup-db.sh all

# Backup specific database
./scripts/backup-db.sh postgres

# List backups
ls -la /opt/vps/backups/
```

### SSL Certificate Check

```bash
# Check all SSL certificates
./vps-cli check-ssl

# Check specific domain
./vps-cli check-ssl example.com
```

---

## 🛡️ Security Notes

### After Installation

1. **Change default passwords** for Nginx Proxy Manager
2. **Configure SSH keys** for deploy user
3. **Review firewall rules** with `ufw status`
4. **Set up Fail2Ban** notifications
5. **Enable SSL** for all services
6. **Review security audit** with `./vps-cli audit-security`

### Best Practices

- Use strong passwords and SSH keys
- Enable 2FA where possible
- Regularly update system packages
- Monitor logs for suspicious activity
- Test backup restoration procedures

---

## 📊 Repository Structure

```
vps-starter-kit/
├── install.sh                      # Bootstrap script
├── vps-cli                         # CLI tool
├── README.md                       # This file
├── CHANGELOG.md                    # Version history
├── config/
│   ├── platform.yml               # Platform config
│   └── README.md
├── vps-app/
│   └── app-template/              # App template
├── vps-db/
│   ├── postgres/
│   ├── mysql/
│   ├── redis/
│   └── sqlserver/
├── vps-infra/
│   ├── nginx-proxy-manager/
│   └── shared/
│       └── scripts/
├── vps-monitoring/
│   ├── netdata/
│   ├── prometheus-grafana/
│   └── uptime-kuma/
├── vps-security/
│   ├── ssh/
│   ├── fail2ban/
│   ├── waf/
│   └── audit/
├── vps-secrets/
│   └── scripts/
├── vps-alerting/
├── vps-platform/
│   ├── scripts/
│   └── registry/
├── vps-vpn/
│   └── wireguard/
├── plugins/
│   ├── minio/
│   ├── kafka/
│   └── elasticsearch/
└── docs/
    ├── OPERATIONS.md
    ├── SECURITY.md
    ├── BACKUP_AND_RESTORE.md
    ├── DISASTER_RECOVERY.md
    ├── MONITORING.md
    └── CICD_V3.md
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Docker and the Docker Compose community
- Nginx Proxy Manager team
- OWASP for the Core Rule Set
- All contributors and maintainers

---

<p align="center">
  <strong>Made with ❤️ for the self-hosted community</strong>
</p>
