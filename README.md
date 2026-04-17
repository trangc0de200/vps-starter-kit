# 🚀 VPS Starter Kit Repository Template (Production-Ready)

This repository provides a **production-ready VPS starter kit** for bootstrapping an Ubuntu 24.04 server using Docker in a consistent, repeatable way.

It is designed so you can:

1. Buy a new VPS  
2. Upload or `git clone` this repository  
3. Run `sudo ./install.sh`  
4. Start only the services you need from `vps-infra`, `vps-db`, and `vps-app`  

---

# 📁 Repository Structure

```text
vps-starter-kit/
├── install.sh
├── README.md
├── .github/
│   └── workflows/
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

# ⚙️ What `install.sh` Does

The bootstrap script will:

- Update and upgrade Ubuntu 24.04
- Install essential system packages
- Install Docker Engine and Docker Compose plugin
- Enable Docker on system boot
- Create a deployment user
- Add the user to `sudo` and `docker` groups
- Enable UFW firewall
- Enable Fail2Ban
- Create a standardized VPS directory structure
- Create shared Docker networks:
  - `proxy_network`
  - `db_network`
- Scaffold Nginx Proxy Manager
- Copy all templates from this repository into the VPS

---

# ⚡ Quick Start

```bash
chmod +x install.sh
sudo ./install.sh
```

Or run with custom environment variables:

```bash
sudo BOOTSTRAP_USER=deployer      VPS_ROOT=/opt/vps      INSTALL_NPM=yes      ENABLE_UFW=yes      ENABLE_FAIL2BAN=yes      TZ_VALUE=UTC      ./install.sh
```

---

# 🚀 After Installation

## 1. Switch to the deploy user

```bash
su - deployer
```

---

## 2. Start Nginx Proxy Manager

```bash
cd /opt/vps/vps-infra/nginx-proxy-manager
docker compose up -d
```

Default admin panel:

```
http://YOUR_SERVER_IP:81
```

⚠️ Change the default credentials immediately.

---

## 3. Start Required Databases

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

## 4. Create a New Application

```bash
cp -r /opt/vps/vps-app/app-template /opt/vps/vps-app/my-app
cd /opt/vps/vps-app/my-app
cp .env.production.example .env.production
nano .env.production
```

---

# 🌐 Networking Conventions

- Public-facing apps connect to: `proxy_network`
- Databases and cache services connect to: `db_network`
- Apps needing database access should connect to both networks if required

---

# 📂 VPS Directory Layout (After Bootstrap)

```text
/opt/vps/
├── backups/
├── vps-app/
├── vps-db/
└── vps-infra/
```

---

# 🔐 Production Best Practices

- Always change default passwords
- Never expose database ports publicly unless absolutely necessary
- Use Nginx Proxy Manager Access Lists to protect:
  - pgAdmin
  - Adminer
  - Portainer
- Automate backups using cron jobs
- Use GitHub Actions for deployment
- Regularly test restore procedures (not just backups)

---

# 📌 Important Files

- `install.sh` → full VPS bootstrap script  
- `vps-infra/nginx-proxy-manager/docker-compose.yml` → reverse proxy layer  
- `vps-db/*` → database and cache templates  
- `vps-app/app-template/*` → application deployment template  
- `.github/workflows/deploy-reusable.yml` → CI/CD deployment template  

---

# 🧠 Notes

This repository is **framework-agnostic**.

It does not enforce any specific tech stack.  
Instead, it provides a **reusable infrastructure foundation** that can be applied to any project.

---

# ✅ Summary

This starter kit helps you transform a fresh VPS into:

✔ A structured, maintainable environment  
✔ A repeatable deployment platform  
✔ A production-ready DevOps foundation  

---

# 🚀 Recommended Next Steps

- Add CI/CD pipelines for each app
- Configure automated backups
- Add monitoring (Netdata / Grafana)
- Implement staging vs production environments
- Add CDN (Cloudflare)

---

# 👨‍💻 Author

Designed for real-world production use.

Customize it to fit your DevOps workflow.
