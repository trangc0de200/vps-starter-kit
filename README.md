# 🚀 VPS Starter Kit (V7.2 Complete - Full, No-Compromise DevOps Platform Template)

This repository is a full, production-oriented VPS starter platform for Ubuntu 24.04 built around Docker, repeatable operations, and practical DevOps workflows.

It is intended to help you turn a freshly provisioned VPS into a structured, reusable platform that supports reverse proxy and HTTPS, databases and cache, application deployment, backup and restore workflows, GitHub Actions CI/CD, monitoring and observability, baseline security hardening, multi-project operations, and platform-style helper tooling.

This V7.2 release keeps all previously introduced layers from V1 to V7.1 and improves the package with fuller documentation, stronger operator helpers, and a more complete platform registry model.

## Main Goals

This template is designed to help you:
1. provision a fresh VPS
2. clone this repository
3. run the bootstrap script
4. start only the components you need
5. deploy applications consistently
6. operate the VPS using repeatable scripts and workflows

This repository is meant to be more than a random collection of Docker Compose files. It is meant to be the operational baseline for your self-hosted application platform.

## Platform Capabilities

### Infrastructure
- Docker Engine
- Docker Compose plugin
- UFW firewall
- Fail2Ban
- deploy user bootstrap
- shared Docker networks
- Nginx Proxy Manager

### Databases and Cache
- PostgreSQL
- MySQL
- Redis
- SQL Server

### Application Delivery
- generic app template
- environment-aware deployment scripts
- migration hook
- health check hook
- rollback hook
- CI/CD-ready layout

### Backup and Recovery
- database backup scripts
- backup verification helper
- retention helper
- off-site sync placeholder
- restore note placeholders
- disaster recovery documentation

### Monitoring and Observability
- Netdata template
- Uptime Kuma template
- Prometheus + Grafana starter template
- endpoint check helper
- SSL expiration check helper
- disk and container checks

### Security Hardening
- SSH hardening templates
- Fail2Ban jail template
- security audit helper
- open port review helper
- firewall review helper
- operator guidance for protecting internal tools

### Platform Layer
- `vps-cli`
- centralized config
- plugin folders
- project and service registration helpers
- platform status helper
- service bootstrap helper
- config validation helper

## Repository Structure

```text
vps-starter-kit/
├── install.sh
├── vps-cli
├── VERSION
├── CHANGELOG.md
├── README.md
├── config/
│   ├── README.md
│   └── platform.yml
├── plugins/
│   ├── minio/
│   ├── kafka/
│   └── elasticsearch/
├── docs/
│   ├── OPERATIONS.md
│   ├── SECURITY.md
│   ├── BACKUP_AND_RESTORE.md
│   ├── CICD_V3.md
│   ├── DISASTER_RECOVERY.md
│   ├── MONITORING.md
│   └── PLATFORM_V7.md
├── .github/
│   └── workflows/
├── vps-app/
│   └── app-template/
├── vps-db/
│   ├── postgres/
│   ├── mysql/
│   ├── redis/
│   └── sqlserver/
├── vps-infra/
│   ├── nginx-proxy-manager/
│   └── shared/
├── vps-monitoring/
│   ├── netdata/
│   ├── uptime-kuma/
│   └── prometheus-grafana/
└── vps-security/
    ├── ssh/
    ├── fail2ban/
    └── audit/
```

## Quick Start

```bash
git clone <your-repo-url>
cd vps-starter-kit
chmod +x install.sh vps-cli
sudo ./install.sh
```

You can also pass environment variables for bootstrap customization:

```bash
sudo BOOTSTRAP_USER=deployer \
     VPS_ROOT=/opt/vps \
     INSTALL_NPM=yes \
     AUTO_START_NPM=yes \
     ENABLE_UFW=yes \
     ENABLE_FAIL2BAN=yes \
     INSTALL_CRON_EXAMPLES=yes \
     TZ_VALUE=UTC \
     PROXY_NETWORK=proxy_network \
     DB_NETWORK=db_network \
     ./install.sh
```

## What the Bootstrap Script Does

The `install.sh` script is designed to be the single bootstrap entry point for a fresh Ubuntu 24.04 VPS.

It will update the operating system, install base system packages, install Docker Engine and Docker Compose plugin, create the deploy user if needed, add that user to `sudo` and `docker`, enable UFW, enable Fail2Ban, create the standard VPS folder layout, create Docker networks for proxy and database traffic, copy the platform templates into the VPS root, prepare helper scripts, auto-start Nginx Proxy Manager if enabled, and install operator helper commands into `/opt/vps/scripts/`.

## Operator Tooling

You still have direct access to raw Docker Compose files, shell scripts, cron examples, and GitHub Actions workflows.

You also get:
- `vps-cli`
- project registration helpers
- service registration helpers
- service bootstrap helper
- platform status helper
- config validation helper

Example commands:

```bash
./vps-cli status
./vps-cli show-config
./vps-cli validate-config
./vps-cli list-services
./vps-cli backup-all
./vps-cli verify-backups
./vps-cli check-containers
./vps-cli check-disk
./vps-cli check-endpoints https://example.com/health
./vps-cli check-ssl example.com
./vps-cli cleanup
./vps-cli audit-security
```

Bootstrap also installs these convenience scripts under `/opt/vps/scripts/`:
- `/opt/vps/scripts/vps-cli`
- `/opt/vps/scripts/create-app.sh`
- `/opt/vps/scripts/register-project.sh`
- `/opt/vps/scripts/register-service.sh`

## Final Outcome

When used properly, this repository helps turn a VPS into a reusable, production-ready, self-hosted DevOps platform template.

It is still a template, not a fully managed platform. You still need to provide real domains, real secrets, real environment files, real app-specific migration commands, real health endpoints, and real alerting integrations.
