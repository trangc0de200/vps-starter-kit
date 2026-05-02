# Database Connection Pooling

## Overview

Connection pooling solutions for PostgreSQL and MySQL to optimize database connections and improve application performance.

## Components

| Tool | Database | Port | Description |
|------|----------|------|-------------|
| **PgBouncer** | PostgreSQL | 5433 | Lightweight connection pooler |
| **ProxySQL** | MySQL | 6033 | Advanced SQL-aware proxy |

## Why Connection Pooling?

| Problem | Solution |
|---------|----------|
| Too many connections | Pool shares connections |
| Connection overhead | Reuse existing connections |
| Database overload | Limit active connections |
| Connection spikes | Queue excess requests |

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   App 1     │────▶│             │────▶│             │
├─────────────┤     │  PgBouncer  │     │ PostgreSQL  │
│   App 2     │────▶│  (Pooler)   │────▶│  (Primary) │
├─────────────┤     │             │     │             │
│   App N     │────▶│  :5433      │────▶│   :5432    │
└─────────────┘     └─────────────┘     └─────────────┘

    Client Pool           Pooler            Database
    Connections           Mode               Connections
    (unlimited)           (20-50)           (configured)
```

## Quick Start

### PgBouncer (PostgreSQL)

```bash
cd vps-db/pooling/pgbouncer
cp .env.example .env
docker-compose up -d

# Connect via pooler
psql -h localhost -p 5433 -U postgres
```

### ProxySQL (MySQL)

```bash
cd vps-db/pooling/proxysql
cp .env.example .env
docker-compose up -d

# Connect via proxy
mysql -h localhost -P 6033 -u root -p
```

## Benchmarks

Typical improvements with connection pooling:

| Metric | Without Pool | With Pool |
|--------|-------------|-----------|
| Connections | 1000 | 50 |
| Latency | 15ms | 3ms |
| Throughput | 500 req/s | 5000 req/s |
| DB CPU | 95% | 40% |

## Documentation

- [PgBouncer Setup](pgbouncer/)
- [ProxySQL Setup](proxysql/)
