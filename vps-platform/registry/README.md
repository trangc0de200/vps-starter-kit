# Platform Registry

Central registry for tracking all deployed services and their configurations.

## Overview

The registry maintains a JSON database of all services deployed through the VPS Platform, including:
- Service metadata
- Deployment status
- Health status
- Version information
- Configuration paths

## Registry Structure

```json
{
  "services": [
    {
      "name": "myapp",
      "path": "/opt/myapp",
      "stack": "docker",
      "version": "v1.2.0",
      "domain": "myapp.example.com",
      "status": "running",
      "health": "healthy",
      "monitoring": "prometheus",
      "created_at": "2024-01-15T10:30:00Z",
      "last_deploy": "2024-01-20T15:45:00Z",
      "last_restart": "2024-01-18T08:00:00Z"
    }
  ]
}
```

## Fields

| Field | Type | Description |
|-------|------|-------------|
| name | string | Service name |
| path | string | Filesystem path |
| stack | string | Deployment stack (docker/kubernetes) |
| version | string | Current version |
| domain | string | Domain name |
| status | string | Deployment status |
| health | string | Health status |
| monitoring | string | Monitoring stack |
| created_at | timestamp | First deployment |
| last_deploy | timestamp | Last deploy time |
| last_restart | timestamp | Last restart time |

## Commands

### Generate Report

```bash
./scripts/registry_report.sh --generate
```

Updates health status for all registered services.

### List Services

```bash
./scripts/registry_report.sh --list
```

### Filter by Service

```bash
./scripts/registry_report.sh --service myapp
```

### Export

```bash
# JSON
./scripts/registry_report.sh --export json

# CSV
./scripts/registry_report.sh --export csv --output report.csv

# Markdown
./scripts/registry_report.sh --export markdown --output report.md
```

## Manual Operations

### Add Service

```bash
# Edit registry directly
nano registry/services.json

# Or use jq
jq '.services += [{
  "name": "newapp",
  "path": "/opt/newapp",
  "status": "deployed"
}]' registry/services.json > tmp.json && mv tmp.json registry/services.json
```

### Update Service

```bash
# Update version
jq '.services |= map(if .name == "myapp" then .version = "v2.0.0" else . end)' \
    registry/services.json > tmp.json && mv tmp.json registry/services.json

# Update status
jq '.services |= map(if .name == "myapp" then .status = "stopped" else . end)' \
    registry/services.json > tmp.json && mv tmp.json registry/services.json
```

### Remove Service

```bash
jq '.services |= map(select(.name != "myapp"))' \
    registry/services.json > tmp.json && mv tmp.json registry/services.json
```

## Integration

### Automatic Registration

Services are automatically registered when bootstrapped:

```bash
./scripts/bootstrap_project.sh --name myapp --path /opt/myapp
```

### Automatic Updates

The registry is updated by:
- `lifecycle_restart.sh` - Updates on restart
- `lifecycle_redeploy.sh` - Updates on redeploy
- `registry_report.sh --generate` - Updates health

## Health Checks

Health status is determined by:

1. **Script check**: `health/health.sh` if exists
2. **Docker check**: Container running status
3. **Default**: "unknown"

## Reporting

### Daily Report

```bash
# Add to crontab
0 6 * * * cd /opt/vps-platform && ./scripts/registry_report.sh --generate --export markdown > /root/daily-report.md
```

### Service Status

```bash
# Get all healthy services
jq '.services[] | select(.health == "healthy")' registry/services.json

# Get all stopped services
jq '.services[] | select(.status == "stopped")' registry/services.json

# Count by status
jq '[.services[].status] | group_by(.) | map({status: .[0], count: length})' registry/services.json
```

## Backup

The registry should be backed up regularly:

```bash
# Backup registry
cp registry/services.json registry/services.json.bak.$(date +%Y%m%d)
```

## Migration

### Move Service Path

```bash
# Update all paths
jq '.services |= map(if .path | contains("/old/path") then .path |= gsub("/old/path"; "/new/path") else . end)' \
    registry/services.json > tmp.json && mv tmp.json registry/services.json
```

## Troubleshooting

### jq Not Found

```bash
# Install jq
apt install jq
# or
brew install jq
```

### Empty Registry

```bash
echo '{"services": []}' > registry/services.json
```
