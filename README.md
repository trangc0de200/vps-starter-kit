# 🚀 VPS Starter Kit (Docker DevOps Template)

This repository is an **upgraded VPS starter kit** for bootstrapping a fresh **Ubuntu 24.04** server into a reusable, production-oriented Docker platform.

It is designed for teams and individuals who want a clean operational baseline for:

- reverse proxy and HTTPS
- databases and cache
- application deployment
- backup and restore workflows
- GitHub Actions CI/CD
- shared operational scripts
- long-term maintainability

This version keeps the original starter-kit purpose intact while expanding it with:

- stronger shared operational scripts
- better bootstrap automation
- richer documentation
- more complete service templates
- reusable CI/CD patterns
- better day-to-day administration helpers

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
- deploy, migrate, health check, rollback script skeletons
- CI/CD-ready folder layout
- environment example files

### Shared Operations

- shared backup orchestrator
- shared health check runner
- Docker cleanup helper
- VPS info script
- service listing helper
- cron examples
- operations documentation

---

## 📁 Repository Structure

```text
vps-starter-kit/
├── install.sh
├── README.md
├── docs/
│   ├── OPERATIONS.md
│   ├── SECURITY.md
│   └── BACKUP_AND_RESTORE.md
├── .github/
│   └── workflows/
│       ├── deploy-reusable.yml
│       └── deploy-example-app.yml
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
- create shared helper scripts
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

A more detailed operational view:

```text
/opt/vps/
├── backups/
│   ├── postgres/
│   ├── mysql/
│   ├── redis/
│   ├── sqlserver/
│   └── npm/
├── logs/
├── scripts/
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

### Important

Change the default administrator credentials immediately after first login.

Recommended responsibilities for Nginx Proxy Manager:

- domain routing
- SSL certificates with Let's Encrypt
- Force SSL
- Access Lists for admin tools
- protection for dashboards and internal tools

---

## 🗄️ Database and Cache Services

Each service is isolated in its own folder and includes:

- `.env.example`
- `docker-compose.yml`
- backup script template
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
cp docker-compose.yml.example docker-compose.yml
nano .env.production
```

Then customize:

- `docker-compose.yml`
- `scripts/migrate.sh`
- `scripts/healthcheck.sh`
- `scripts/rollback.sh`
- `scripts/backup.sh` if your app owns state

This app template is intentionally generic so it can be adapted for:

- Next.js
- Nuxt.js
- Vue
- NestJS
- Laravel
- Django
- FastAPI
- Spring Boot
- Go

---

## 🔁 CI/CD with GitHub Actions

This repository includes a reusable workflow:

```text
.github/workflows/deploy-reusable.yml
```

Deployment flow:

```text
git push → GitHub Actions → SSH → VPS → docker compose → migrate → healthcheck
```

The template supports:

- reusable SSH deploy
- migration hooks
- health checks
- optional pre-deploy backup
- app-specific workflows calling the shared workflow

---

## 🌐 Networking Conventions

Recommended network usage:

- public apps join `proxy_network`
- databases and cache join `db_network`
- apps needing database access join both networks if needed

### Example

- `nextjs-web` → `proxy_network`
- `postgres` → `db_network`
- `nestjs-api` → `proxy_network` + `db_network`

This keeps public exposure under control and makes service discovery cleaner.

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

Admin tools that should usually be protected:

- pgAdmin
- Adminer
- Portainer
- Netdata
- Grafana
- internal dashboards

See also:

- `docs/SECURITY.md`

---

## 💾 Backups

This kit is backup-ready, and the shared scripts make backup orchestration easier.

Backups are expected to live under:

```text
/opt/vps/backups/
```

Each DB template includes a backup script.

Recommended approach:

- daily scheduled backups
- manual backup before risky changes
- off-site backup later if needed
- regular restore testing

See also:

- `docs/BACKUP_AND_RESTORE.md`

---

## 📌 Important Files

- `install.sh` → full VPS bootstrap
- `vps-infra/nginx-proxy-manager/docker-compose.yml` → reverse proxy stack
- `vps-db/*` → database and cache templates
- `vps-app/app-template/*` → application deployment template
- `.github/workflows/deploy-reusable.yml` → reusable CI/CD workflow
- `docs/OPERATIONS.md` → day-to-day operational notes

---

## 🧠 Design Philosophy

This repository is **framework-agnostic**.

It does not force a specific backend or frontend stack.

Instead, it provides a **shared infrastructure foundation** so you can deploy many kinds of apps using the same conventions.

That makes it useful for:

- personal infrastructure
- freelance / agency delivery
- multi-project VPS hosting
- internal company starter kits

---

## ✅ Summary

This kit helps turn a fresh VPS into:

- a structured deployment platform
- a reusable Docker hosting base
- a safer production workflow
- a cleaner DevOps foundation

---

## 🛠 Recommended Next Steps

After bootstrap, the best next improvements are:

- add real production `.env` files
- add cron jobs for DB backups
- add real app-specific deploy scripts
- configure Nginx Proxy Manager domains
- add GitHub repository secrets
- enable CI/CD per application
- add monitoring and alerting later

---

## 👨‍💻 Notes

This repository is meant to be customized.  
Treat it as a strong starting point, not a rigid final product.
