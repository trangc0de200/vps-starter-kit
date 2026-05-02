# VPS Kubernetes Deployment Guide

## Overview

This guide covers deploying the VPS infrastructure to Kubernetes.

## Prerequisites

- Kubernetes 1.24+
- kubectl configured
- Helm 3.x
- Sufficient cluster resources

## Quick Start

### 1. Deploy Base Infrastructure

```bash
# Create namespaces and base resources
kubectl apply -k base/

# Verify
kubectl get namespaces
kubectl get configmaps -n vps-system
```

### 2. Deploy Databases

```bash
# Deploy all databases
kubectl apply -k databases/

# Check status
kubectl get pods -n databases
kubectl get svc -n databases
```

### 3. Deploy Networking

```bash
# Deploy ingress and network policies
kubectl apply -k networking/

# Install cert-manager for TLS
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.0/cert-manager.yaml
```

### 4. Deploy Monitoring

```bash
# Deploy Prometheus + Grafana
kubectl apply -k monitoring/

# Access Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

## Environment-Specific Deployment

### Development

```bash
kubectl apply -k overlays/dev/
```

### Production

```bash
kubectl apply -k overlays/prod/
```

## Helm Deployment

Alternatively, use Helm charts:

```bash
# Add repos
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install components
helm install postgres bitnami/postgresql -n databases --create-namespace
helm install redis bitnami/redis -n databases
helm install prometheus prometheus-community/prometheus -n monitoring
helm install grafana bitnami/grafana -n monitoring
```

## Accessing Services

### Port Forward

```bash
# PostgreSQL
kubectl port-forward -n databases svc/postgres 5432:5432

# Redis
kubectl port-forward -n databases svc/redis 6379:6379

# Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

### LoadBalancer

```bash
# Get external IP
kubectl get svc -n databases

# For databases
kubectl apply -f databases/postgres/service-lb.yaml
```

## Configuration

### Update Secrets

```bash
# Edit secrets
kubectl edit secret postgres-secret -n databases

# Or apply updated secret
kubectl apply -f base/secret.yaml
```

### Update ConfigMaps

```bash
kubectl edit configmap postgres-config -n databases
kubectl rollout restart deployment/postgres -n databases
```

## Scaling

### Manual Scale

```bash
kubectl scale deployment postgres -n databases --replicas=3
```

### Auto Scale (HPA)

```bash
kubectl autoscale deployment web-app -n apps \
  --cpu-percent=70 \
  --min=2 \
  --max=10
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n databases
kubectl describe pod postgres-0 -n databases
kubectl logs postgres-0 -n databases
```

### Check Events

```bash
kubectl get events -n databases --sort-by='.lastTimestamp'
```

### Common Issues

**Pod stuck in Pending**
- Check PVC provisioning
- Check resource quotas
- Check node resources

**Pod stuck in CrashLoopBackOff**
- Check logs: `kubectl logs`
- Check resource limits
- Verify environment variables

## Backup & Restore

### Backup PVC

```bash
# Using Velero
velero backup create postgres-backup --include-namespaces databases

# Manual snapshot
kubectl apply -f backup/snapshot.yaml
```

### Restore from Backup

```bash
# Restore PVC
kubectl apply -f backup/restore.yaml

# Restore database
kubectl exec -it postgres-0 -n databases -- psql -U postgres
```

## Security

### Network Policies

Network policies are deployed by default:
- Databases only accessible from apps namespace
- Apps can only reach databases
- External access via Ingress only

### RBAC

```bash
# Create service account
kubectl apply -f rbac/service-account.yaml

# Bind role
kubectl apply -f rbac/role-binding.yaml
```

## Monitoring

### Prometheus

```bash
# Access Prometheus UI
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

### Grafana

```bash
# Get admin password
kubectl get secret grafana-secret -n monitoring -o jsonpath='{.data.admin-password}' | base64 -d

# Access UI
kubectl port-forward -n monitoring svc/grafana 3000:80
```

## Cleanup

```bash
# Remove all resources
kubectl delete -k ./ --grace-period=30

# Remove namespaces
kubectl delete namespaces databases networking monitoring logging apps
```
