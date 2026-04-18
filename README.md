# 🚀 VPS Starter Kit (V7 Complete - Platformized Docker DevOps Template)

This repository provides a **complete V7 upgrade** of the VPS Starter Kit for bootstrapping and operating a production-oriented Docker platform on **Ubuntu 24.04**.

This version keeps all previously available functionality and adds a **complete V7 platformization layer**, including:

- `vps-cli` wrapper commands
- centralized platform config
- plugin-style service folders
- multi-project conventions
- platform status helpers
- service bootstrap helpers
- config validation helper
- extensible structure for future internal tooling

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
- baseline security hardening
- platform-style operations across multiple projects

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
- security helpers
- platform helpers
- cron examples
- operations, security, backup, CI/CD, disaster recovery, monitoring, and platform documentation

### Monitoring and Observability
- Netdata stack template
- Uptime Kuma stack template
- Prometheus + Grafana starter template

### Security Hardening
- SSH config template
- Fail2Ban jail template
- security audit helper
- open ports helper
- UFW review helper

### Platformization (V7)
- `vps-cli`
- `config/platform.yml`
- plugin folders
- multi-project conventions
- config validation helper
- service bootstrap helper
- platform status helper

---

## 📁 Repository Structure

```text
vps-starter-kit/
├── install.sh
├── vps-cli
├── VERSION
├── CHANGELOG.md
├── README.md
├── config/
│   └── platform.yml
├── plugins/
│   ├── minio/
│   ├── kafka/
│   └── elasticsearch/
├── docs/
├── .github/workflows/
├── vps-app/
├── vps-db/
├── vps-infra/
├── vps-monitoring/
└── vps-security/
```

---

## ⚡ Quick Start

```bash
git clone <your-repo-url>
cd vps-starter-kit
chmod +x install.sh vps-cli
sudo ./install.sh
```

### Optional bootstrap variables

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

## 🧰 V7 Platform Commands

Example:

```bash
./vps-cli status
./vps-cli list-services
./vps-cli backup-all
./vps-cli check-containers
./vps-cli show-config
```

The `vps-cli` wrapper does not replace lower-level shell access.  
It provides a cleaner entry point for repeated operational tasks.

---

## 🧠 Platform Design Philosophy

V7 does **not** remove any direct control from previous versions.  
Instead, it adds a higher-level operating layer on top of the existing building blocks.

That means you still keep:
- raw Docker Compose files
- direct scripts
- direct cron usage
- direct GitHub Actions workflows

But you now also gain:
- shared wrapper commands
- centralized config
- plugin-style expansion
- better multi-project conventions

---

## ✅ Summary

This V7 Complete release helps turn a fresh VPS into:

- a structured deployment platform
- a reusable Docker hosting base
- a safer production workflow
- a cleaner DevOps foundation
- a more complete CI/CD platform
- a more complete backup and recovery platform
- a more complete monitoring and observability platform
- a more complete security hardening baseline
- a more complete multi-project platform layer

---

## 👨‍💻 Notes

This repository is meant to be customized.  
Treat it as a strong starting point, not a rigid final product.
