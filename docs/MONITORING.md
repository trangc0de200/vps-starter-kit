# Monitoring and Observability Guide

This document explains the V5 monitoring layer.

## Included Monitoring Stacks
- Netdata
- Uptime Kuma
- Prometheus + Grafana starter template

## Recommended Monitoring Scope
- VPS resource usage
- container availability
- app health endpoints
- SSL expiration awareness
- disk usage trends
- restart count trends

## Suggested First Rollout
1. Start Netdata
2. Start Uptime Kuma
3. Add your public app URLs
4. Review dashboards weekly
5. Add alerting later

## Important Principle
Monitoring should help detect:
- service down
- disk pressure
- memory pressure
- unhealthy containers
- missed backups
