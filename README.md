# 🚀 VPS Starter Kit (V5 Complete - Production-Ready Docker DevOps Template)

This repository provides a **complete V5 upgrade** of the VPS Starter Kit for bootstrapping and operating a production-oriented Docker platform on **Ubuntu 24.04**.

This version keeps all previously available functionality and adds a **complete V5 monitoring and observability layer**, including:

- Netdata template
- Uptime Kuma template
- Prometheus + Grafana starter template
- shared monitoring helpers
- endpoint and SSL check helpers
- container and disk health checks
- monitoring documentation
- monitoring cron example
- alert workflow placeholders

It is designed for teams and individuals who want a practical self-hosted DevOps foundation for:

- reverse proxy and HTTPS
- databases and cache
- application deployment
- backups and restore workflows
- GitHub Actions CI/CD
- shared operational scripts
- long-term maintainability
- disaster recovery readiness
- monitoring and observability

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
- monitoring helpers
- cron examples
- operations, security, backup, CI/CD, disaster recovery, and monitoring documentation

### Monitoring and Observability
- Netdata stack template
- Uptime Kuma stack template
- Prometheus + Grafana starter template
- endpoint check helper
- SSL expiration check helper
- container check helper
- disk usage check helper

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
│   ├── DISASTER_RECOVERY.md
│   └── MONITORING.md
├── .github/
│   └── workflows/
│       ├── deploy-reusable.yml
│       ├── deploy-example-app.yml
│       ├── deploy-staging-example.yml
│       ├── deploy-production-example.yml
│       ├── manual-deploy-example.yml
│       ├── rollback-example.yml
│       ├── backup-report-example.yml
│       └── monitoring-report-example.yml
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
└── vps-monitoring/
    ├── netdata/
    ├── uptime-kuma/
    └── prometheus-grafana/
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
├── vps-infra/
└── vps-monitoring/
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
- restore notes placeholder

---

## 🔁 CI/CD Highlights

This version keeps the complete V3 deployment model and the V4 recovery layer, then extends the operational platform with V5 monitoring documentation and examples.

See:
- `docs/CICD_V3.md`
- `docs/BACKUP_AND_RESTORE.md`
- `docs/DISASTER_RECOVERY.md`
- `docs/MONITORING.md`

---

## 📊 V5 Monitoring Highlights

This version adds:

- Netdata deployment template
- Uptime Kuma deployment template
- Prometheus + Grafana starter template
- endpoint check helper
- SSL expiration check helper
- container check helper
- disk usage check helper
- monitoring report workflow example

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

This V5 Complete release helps turn a fresh VPS into:

- a structured deployment platform
- a reusable Docker hosting base
- a safer production workflow
- a cleaner DevOps foundation
- a more complete CI/CD platform
- a more complete backup and recovery platform
- a more complete monitoring and observability platform

---

## 🛠 Recommended Next Steps

After bootstrap, the best next improvements are:

- add real production and staging `.env` files
- connect backup scripts to cron
- connect monitoring scripts to cron or alerting
- configure Nginx Proxy Manager domains
- add GitHub repository secrets
- connect workflows to real app folders
- wire monitoring alerts to Slack or Telegram later

---

## 👨‍💻 Notes

This repository is meant to be customized.  
Treat it as a strong starting point, not a rigid final product.
