# Shared Scripts Directory

This directory contains reusable scripts for operational management.

## Scripts

### healthcheck_all.sh

Check health of all services.

```bash
./healthcheck_all.sh
```

### check_containers.sh

Display Docker container status.

```bash
./check_containers.sh
```

### check_disk_usage.sh

Show disk usage for all volumes.

```bash
./check_disk_usage.sh
```

### check_ssl_expiry.sh

Monitor SSL certificate expiration.

```bash
./check_ssl_expiry.sh
```

### check_endpoints.sh

HTTP health check for endpoints.

```bash
./check_endpoints.sh
```

### show_vps_info.sh

Display system information.

```bash
./show_vps_info.sh
```

### backup_all.sh

Backup all platform data.

```bash
./backup_all.sh
```

### verify_backups.sh

Validate backup integrity.

```bash
./verify_backups.sh
```

### audit_security.sh

Comprehensive security audit.

```bash
./audit_security.sh
```

### review_open_ports.sh

List all listening ports.

```bash
./review_open_ports.sh
```

### review_ufw.sh

Check UFW firewall status.

```bash
./review_ufw.sh
```

### cleanup.sh

Clean old logs and unused resources.

```bash
./cleanup.sh --all
```

### apply_retention.sh

Apply data retention policies.

```bash
./apply_retention.sh
```

### register_service.sh

Register a new service.

```bash
./register_service.sh myservice
```

### register_project.sh

Register a new project.

```bash
./register_project.sh myproject
```

### create_app.sh

Scaffold a new application.

```bash
./create_app.sh myapp
```

### bootstrap_service.sh

Bootstrap a new service.

```bash
./bootstrap_service.sh myservice
```

### rollback_app.sh

Rollback application to previous version.

```bash
./rollback_app.sh myapp
```

### platform_status.sh

Show platform overview.

```bash
./platform_status.sh
```

### validate_config.sh

Validate configuration files.

```bash
./validate_config.sh
```

### list_services.sh

List all registered services.

```bash
./list_services.sh
```
