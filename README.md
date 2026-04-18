# 🚀 VPS Starter Kit (V4 Complete - Production-Ready Docker DevOps Template)

This repository provides a **complete V4 upgrade** of the VPS Starter Kit for bootstrapping and operating a production-oriented Docker platform on **Ubuntu 24.04**.

This version keeps all previously available functionality and adds a **complete V4 backup and disaster recovery layer**, including:

- backup tiering guidance
- backup verification helpers
- restore workflow placeholders
- restore test checklist
- off-site sync placeholders
- stronger retention and recovery documentation
- operational backup orchestration improvements

It is designed for teams and individuals who want a practical self-hosted DevOps foundation for:

- reverse proxy and HTTPS
- databases and cache
- application deployment
- backups and restore workflows
- GitHub Actions CI/CD
- shared operational scripts
- long-term maintainability
- disaster recovery readiness

---

## ✨ What This Starter Kit Includes

### Core Infrastructure
- Docker Engine
- Docker Compose plugin
- UFW firewall
- Fail2Ban
- deployment user bootstrap
- shared Docker networks
- Nginx Proxy Manager

### Databases and Cache
- PostgreSQL template
- MySQL template
- Redis template
- SQL Server template

### Application Deployment
- reusable app template
- deploy, migrate, health check, backup, and rollback script skeletons
- staging and production environment examples
- CI/CD-ready folder layout

### Shared Operations
- shared backup orchestrator
- shared health check runner
- Docker cleanup helper
- VPS info script
- service listing helper
- rollback helper
- backup verification helper
- retention helper
- off-site sync placeholder
- cron examples
- operations, security, backup, and CI/CD documentation

### V3 + V4 Platform Additions
- reusable deployment workflow
- staging workflow pattern
- production workflow pattern
- manual deployment workflow
- rollback workflow
- concurrency protection
- environment-aware app template
- backup and recovery readiness layer

---

## 📁 Repository Structure

```text
vps-starter-kit/
├── install.sh
├── VERSION
├── CHANGELOG.md
├── README.md
├── docs/
│   ├── OPERATIONS.md
│   ├── SECURITY.md
│   ├── BACKUP_AND_RESTORE.md
│   ├── CICD_V3.md
│   └── DISASTER_RECOVERY.md
├── .github/
│   └── workflows/
│       ├── deploy-reusable.yml
│       ├── deploy-example-app.yml
│       ├── deploy-staging-example.yml
│       ├── deploy-production-example.yml
│       ├── manual-deploy-example.yml
│       ├── rollback-example.yml
│       └── backup-report-example.yml
├── vps-app/
│   └── app-template/
├── vps-db/
│   ├── postgres/
│   ├── mysql/
│   ├── redis/
│   └── sqlserver/
└── vps-infra/
    ├── nginx-proxy-manager/
    └── shared/
        ├── bin/
        ├── cron/
        ├── scripts/
        └── templates/
```

---

## ⚡ Quick Start

```bash
git clone <your-repo-url>
cd vps-starter-kit
chmod +x install.sh
sudo ./install.sh
```

### With optional environment variables

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

---

## ⚙️ What `install.sh` Does

The bootstrap script will:

- update and upgrade Ubuntu
- install base packages
- install Docker Engine and Docker Compose plugin
- enable Docker on boot
- create the deployment user
- add the deployment user to `sudo` and `docker`
- enable UFW
- enable Fail2Ban
- create the VPS directory structure
- create shared Docker networks:
  - `proxy_network`
  - `db_network`
- scaffold Nginx Proxy Manager
- optionally auto-start Nginx Proxy Manager
- copy all templates into the target VPS root
- ensure shared helper scripts are ready
- optionally install cron examples

---

## 🧱 VPS Directory Layout After Bootstrap

By default, the script creates:

```text
/opt/vps/
├── backups/
├── logs/
├── scripts/
├── vps-app/
├── vps-db/
└── vps-infra/
```

---

## 🌐 Reverse Proxy Layer

Nginx Proxy Manager is used as the shared reverse proxy entrypoint for all public services.

Start it manually:

```bash
cd /opt/vps/vps-infra/nginx-proxy-manager
docker compose up -d
```

Default admin UI:

```text
http://YOUR_SERVER_IP:81
```

Change the default administrator credentials immediately after first login.

---

## 🗄️ Database and Cache Services

Each service is isolated in its own folder and includes:

- `.env.example`
- `docker-compose.yml`
- backup script
- service-specific README

### PostgreSQL

```bash
cd /opt/vps/vps-db/postgres
cp .env.example .env
nano .env
docker compose up -d
```

### MySQL

```bash
cd /opt/vps/vps-db/mysql
cp .env.example .env
nano .env
docker compose up -d
```

### Redis

```bash
cd /opt/vps/vps-db/redis
cp .env.example .env
cp redis.conf.example redis.conf
nano .env
nano redis.conf
docker compose up -d
```

### SQL Server

```bash
cd /opt/vps/vps-db/sqlserver
cp .env.example .env
nano .env
docker compose up -d
```

---

## 🚀 Create a New Application

Create a new app from the template:

```bash
cp -r /opt/vps/vps-app/app-template /opt/vps/vps-app/my-app
cd /opt/vps/vps-app/my-app
cp .env.production.example .env.production
cp .env.staging.example .env.staging
cp docker-compose.yml.example docker-compose.yml
nano .env.production
```

Then customize:

- `docker-compose.yml`
- `scripts/deploy.sh`
- `scripts/migrate.sh`
- `scripts/healthcheck.sh`
- `scripts/rollback.sh`
- `scripts/backup.sh` if your app owns state

---

## 🔁 V3 CI/CD Highlights

This version keeps the complete V3 deployment model:

- staging and production workflow separation
- reusable workflow with environment inputs
- manual deployment support
- rollback workflow
- deploy concurrency control
- environment-aware scripts

See:

```text
docs/CICD_V3.md
```

---

## 💾 V4 Backup and Recovery Highlights

This version upgrades the backup and recovery layer with:

- shared backup verification helper
- shared retention helper
- shared off-site sync placeholder
- restore test checklist
- disaster recovery notes
- backup report workflow example
- extended cron examples for backup operations

See:

```text
docs/BACKUP_AND_RESTORE.md
docs/DISASTER_RECOVERY.md
```

---

## 🔐 Security Best Practices

Recommended baseline:

- expose only `80` and `443` publicly
- keep databases internal only
- use strong passwords in all `.env` files
- enable UFW
- enable Fail2Ban
- use SSH keys
- avoid public DB access unless absolutely necessary
- protect pgAdmin / Adminer / Portainer with NPM Access Lists

See also:

- `docs/SECURITY.md`

---

## ✅ Summary

This V4 Complete release helps turn a fresh VPS into:

- a structured deployment platform
- a reusable Docker hosting base
- a safer production workflow
- a cleaner DevOps foundation
- a more complete CI/CD platform
- a more complete backup and recovery platform

---

## 🛠 Recommended Next Steps

After bootstrap, the best next improvements are:

- add real production and staging `.env` files
- connect backup scripts to cron
- test restore procedures in a staging environment
- configure Nginx Proxy Manager domains
- add GitHub repository secrets
- connect workflows to real app folders
- add monitoring and alerting later

---

## 👨‍💻 Notes

This repository is meant to be customized.  
Treat it as a strong starting point, not a rigid final product.
