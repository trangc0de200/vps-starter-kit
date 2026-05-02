# VPS Starter Kit - Kubernetes Manifests

## Overview

Production-ready Kubernetes manifests for deploying the VPS infrastructure.

## Structure

```
vps-k8s/
├── base/                    # Base manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── storageclass.yaml
├── databases/               # Database deployments
│   ├── postgres/
│   ├── mysql/
│   └── redis/
├── networking/              # Ingress, services
│   ├── ingress-nginx.yaml
│   ├── cert-manager.yaml
│   └── network-policies.yaml
├── monitoring/              # Observability
│   ├── prometheus/
│   ├── grafana/
│   └── elk/
└── apps/                   # Sample applications
    └── web-app/
```

## Prerequisites

- Kubernetes 1.24+
- Helm 3.x
- kubectl configured

## Quick Start

### Deploy All

```bash
# Using Kustomize
kubectl apply -k base/
kubectl apply -k databases/
kubectl apply -k networking/
kubectl apply -k monitoring/

# Or deploy all at once
kubectl apply -k ./
```

### Deploy with Helm

```bash
# Add Helm repos
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Install components
helm install postgres bitnami/postgresql -n databases
helm install redis bitnami/redis -n databases
helm install ingress ingress-nginx/ingress-nginx -n networking
```

## Documentation

- [Deployment Guide](docs/DEPLOYMENT.md)
- [Configuration](docs/CONFIGURATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
