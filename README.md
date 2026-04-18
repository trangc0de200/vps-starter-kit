# 🚀 VPS Starter Kit (V6 Complete - Production-Ready Docker DevOps Template)

This repository provides a **complete V6 upgrade** of the VPS Starter Kit for bootstrapping and operating a production-oriented Docker platform on **Ubuntu 24.04**.

This version keeps all previously available functionality and adds a **complete V6 security hardening layer**, including:

- SSH hardening templates
- Fail2Ban templates
- security audit helpers
- open port review helper
- UFW review helper
- Docker security notes
- access protection guidance for internal tools
- security report workflow example
- stronger security documentation

## Included platform layers
- V1 bootstrap foundation
- V2 starter-kit structure improvements
- V3 CI/CD workflows
- V4 backup and disaster recovery helpers
- V5 monitoring and observability templates
- V6 security hardening baseline

## Top-level structure

```text
vps-starter-kit/
├── install.sh
├── VERSION
├── CHANGELOG.md
├── README.md
├── docs/
├── .github/workflows/
├── vps-app/
├── vps-db/
├── vps-infra/
├── vps-monitoring/
└── vps-security/
```

## Quick start

```bash
git clone <your-repo-url>
cd vps-starter-kit
chmod +x install.sh
sudo ./install.sh
```

## Optional bootstrap variables

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

## V6 security additions
- `vps-security/ssh/`
- `vps-security/fail2ban/`
- `vps-security/audit/`
- `docs/SECURITY.md`
- `security-report-example.yml`

## Notes
This repository is meant to be customized. Treat it as a strong starting point, not a rigid final product.
