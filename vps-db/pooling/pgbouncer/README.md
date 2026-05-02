# PgBouncer for PostgreSQL

## Overview

PgBouncer is a lightweight connection pooler for PostgreSQL. It maintains a pool of connections to PostgreSQL and reuses them as needed.

## Features

- **Connection Pooling**: Reduce database connection overhead
- **Statement Mode**: Execute queries without session state
- **Transaction Mode**: Pool at transaction level
- **Server Pooling**: Traditional session pooling
- **Authentication Caching**: Reduce auth overhead
- **Online Restart**: No downtime for config changes

## Modes

### Transaction Mode (Recommended for most apps)

```ini
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
```

### Session Mode

```ini
pool_mode = session
max_client_conn = 500
default_pool_size = 50
```

### Statement Mode

```ini
pool_mode = statement
max_client_conn = 5000
default_pool_size = 10
```

## Quick Start

```bash
cd vps-db/pooling/pgbouncer
cp .env.example .env
# Edit .env with your database credentials

docker-compose up -d

# Test connection
psql -h localhost -p 5433 -U postgres
```

## Connection String

```
# Direct to PostgreSQL
postgresql://user:pass@host:5432/dbname

# Via PgBouncer
postgresql://user:pass@host:5433/dbname
```

## Monitoring

```bash
# Show pools
psql -h localhost -p 5433 -U pgbouncer -c "SHOW POOLS"

# Show clients
psql -h localhost -p 5433 -U pgbouncer -c "SHOW CLIENTS"

# Show servers
psql -h localhost -p 5433 -U pgbouncer -c "SHOW SERVERS"

# Show stats
psql -h localhost -p 5433 -U pgbouncer -c "SHOW STATS"
```
