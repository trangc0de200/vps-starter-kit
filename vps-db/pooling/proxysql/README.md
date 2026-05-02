# ProxySQL for MySQL/MariaDB

## Overview

ProxySQL is a SQL-aware proxy that sits between your application and MySQL/MariaDB servers. It provides advanced connection pooling, query caching, and routing capabilities.

## Features

- **Connection Pooling**: Efficient connection reuse
- **Query Routing**: Route queries to different backends
- **Query Caching**: Cache query results
- **Read/Write Split**: Separate read and write queries
- **Failover**: Automatic backend failover
- **Query Rewriting**: Modify queries on the fly
- **Sharding**: Horizontal query distribution
- **Throttling**: Limit slow queries

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   App 1     │────▶│             │────▶│ Master DB   │
├─────────────┤     │  ProxySQL   │     │   (Write)   │
│   App 2     │────▶│   :6033     │────▶│             │
├─────────────┤     │             │     ├─────────────┤
│   App N     │────▶│  Monitor    │     │ Slave DB    │
└─────────────┘     │   :6092     │────▶│   (Read)    │
                    └─────────────┘     └─────────────┘
```

## Quick Start

```bash
cd vps-db/pooling/proxysql
cp .env.example .env
docker-compose up -d

# Access ProxySQL admin
mysql -h localhost -P 6032 -u admin -padmin -e "SELECT * FROM stats_memory_metrics"
```

## Connection String

```
# Direct to MySQL
mysql://user:pass@host:3306/dbname

# Via ProxySQL
mysql://user:pass@host:6033/dbname

# Admin console
mysql -h host -P 6032 -u admin -p
```

## Key Commands

```sql
-- Show connection pools
SELECT * FROM stats_mysql_connection_pool;

-- Show query statistics
SELECT * FROM stats_mysqlqueries;

-- Show backends
SELECT * FROM mysql_servers;

-- Show users
SELECT * FROM mysql_users;

-- Reload configuration
LOAD MYSQL USERS TO RUNTIME;
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL USERS TO DISK;
SAVE MYSQL SERVERS TO DISK;
```

## Read/Write Split Configuration

ProxySQL can automatically route read queries to replicas and write queries to the master.

```sql
-- Configure query rules
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES (1, 1, '^SELECT.*FOR UPDATE', 0, 1);

INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES (2, 1, '^SELECT', 1, 1);
```
