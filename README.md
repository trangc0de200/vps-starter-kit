# 🚀 VPS Starter Kit (Production-Ready Docker DevOps Template)

This repository is a **full VPS starter kit** for bootstrapping a brand new **Ubuntu 24.04** server into a reusable, production-ready Docker platform.

It is designed for people who want a practical starting point for:

- reverse proxy and HTTPS
- databases and cache
- containerized applications
- backups and restore workflows
- GitHub Actions CI/CD
- consistent folder structure across projects

With this kit, the usual process becomes:

1. buy a new VPS  
2. upload or clone this repository  
3. run `sudo ./install.sh`  
4. start only the services you need  
5. deploy apps into a clean, repeatable structure  

---

## ✨ What This Starter Kit Includes

### Infrastructure
- Docker Engine
- Docker Compose plugin
- UFW firewall
- Fail2Ban
- deploy user bootstrap
- shared Docker networks
- Nginx Proxy Manager

### Databases and Cache
- PostgreSQL template
- MySQL template
- Redis template
- SQL Server template

### App Deployment
- reusable app template
- deploy, migrate, health check, rollback script skeletons
- CI/CD-ready structure

### Operations
- shared helper scripts
- backup-ready layout
- GitHub Actions reusable workflow
- production-oriented README structure

---

## 📁 Repository Structure

```text
vps-starter-kit/
├── install.sh
├── README.md
├── docs/
│   └── OPERATIONS.md
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
sudo BOOTSTRAP_USER=deployer      VPS_ROOT=/opt/vps      INSTALL_NPM=yes      ENABLE_UFW=yes      ENABLE_FAIL2BAN=yes      TZ_VALUE=UTC      PROXY_NETWORK=proxy_network      DB_NETWORK=db_network      ./install.sh
```

---

## ⚙️ What `install.sh` Does

The bootstrap script will:

- update and upgrade Ubuntu
- install base packages
- install Docker Engine and Docker Compose plugin
- enable Docker on boot
- create the deploy user
- add the deploy user to `sudo` and `docker`
- enable UFW
- enable Fail2Ban
- create the VPS directory structure
- create shared Docker networks:
  - `proxy_network`
  - `db_network`
- scaffold Nginx Proxy Manager
- copy all templates into the target VPS root

---

## 🧱 VPS Directory Layout After Bootstrap

By default, the script creates:

```text
/opt/vps/
├── backups/
├── vps-app/
├── vps-db/
└── vps-infra/
```

A more detailed view:

```text
/opt/vps/
├── backups/
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

Start it with:

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
- protecting dashboards and internal tools

---

## 🗄️ Database and Cache Services

Each service is isolated in its own folder and includes:

- `.env.example`
- `docker-compose.yml`
- backup script template

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
nano .env.production
```

Then customize:

- `docker-compose.yml`
- `scripts/migrate.sh`
- `scripts/healthcheck.sh`
- `scripts/rollback.sh`

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

---

## 💾 Backups

This kit is backup-ready, but not all backup cron jobs are enabled automatically by default.

Backups are expected to live under:

```text
/opt/vps/backups/
```

Each DB template includes a backup script skeleton or ready-to-use script.

Recommended approach:

- daily scheduled backups
- manual backup before risky changes
- off-site backup later if needed
- regular restore testing

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
