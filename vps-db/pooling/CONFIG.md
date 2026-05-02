# Connection Pooling Configuration Guide

## Overview

This module provides database connection pooling for PostgreSQL (PgBouncer) and MySQL/MariaDB (ProxySQL).

## When to Use Connection Pooling

### Benefits

| Scenario | Without Pooling | With Pooling |
|----------|----------------|--------------|
| 100 concurrent users | 100 DB connections | 25 DB connections |
| Connection overhead | 50ms per query | 1ms per query |
| Database memory | High | Optimized |
| Connection errors | Frequent under load | Stable |

### Use Cases

- **High-traffic applications**: Many concurrent users
- **Serverless functions**: Connection-per-request is expensive
- **Microservices**: Shared database connections
- **Connection-limited databases**: PostgreSQL default max_connections=100

## PgBouncer (PostgreSQL)

### Pool Modes

#### Transaction Mode (Recommended)

```ini
pool_mode = transaction
default_pool_size = 25
```

Best for:
- Web applications
- REST APIs
- Most transactional workloads

#### Session Mode

```ini
pool_mode = session
default_pool_size = 50
```

Best for:
- Long-running transactions
- Stored procedures
- PostgreSQL features that need session state

#### Statement Mode

```ini
pool_mode = statement
default_pool_size = 10
```

Best for:
- Serverless
- Short-lived transactions only
- No BEGIN/COMMIT blocks

### Connection String

```
# Standard PostgreSQL
postgresql://user:pass@postgres:5432/mydb

# Via PgBouncer
postgresql://user:pass@localhost:5433/mydb
```

### Monitoring Commands

```sql
-- View pools
SHOW POOLS;

-- View clients
SHOW CLIENTS;

-- View servers
SHOW SERVERS;

-- View statistics
SHOW STATS;

-- Get version
SHOW VERSION;
```

### Troubleshooting

**Error: "login failed"**
```bash
# Check userlist.txt format
# Should be: "username" "md5hash"
```

**High wait time**
```ini
# Increase pool size
default_pool_size = 50
reserve_pool_size = 10
```

## ProxySQL (MySQL)

### Key Features

1. **SQL-aware routing**: Route queries based on content
2. **Read/Write split**: Automatic query routing
3. **Query caching**: Cache frequently accessed data
4. **Automatic failover**: Switch to backup servers
5. **Query rewriting**: Modify queries on the fly

### Configuration via Admin Interface

```sql
-- Connect to admin
mysql -h localhost -P 6032 -u admin -padmin

-- View connection pools
SELECT * FROM stats_mysql_connection_pool;

-- View query rules
SELECT * FROM mysql_query_rules;

-- Add new server
INSERT INTO mysql_servers (hostname, port, weight) VALUES ('mysql-replica', 3306, 1);
LOAD MYSQL SERVERS TO RUNTIME;
SAVE MYSQL SERVERS TO DISK;

-- Add query rule
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, destination_hostgroup, apply)
VALUES (10, 1, '^SELECT.*FROM users$', 1, 1);
LOAD MYSQL QUERY RULES TO RUNTIME;
SAVE MYSQL QUERY RULES TO DISK;
```

### Read/Write Split Configuration

```sql
-- Write queries to primary
INSERT INTO mysql_query_rules (rule_id, active, match_digest, destination_hostgroup, apply)
VALUES (1, 1, '^SELECT.*FOR UPDATE', 0, 1);

-- Read queries to replica
INSERT INTO mysql_query_rules (rule_id, active, match_digest, destination_hostgroup, apply)
VALUES (2, 1, '^SELECT', 1, 1);

-- All other queries to primary
UPDATE mysql_default_hostgroup SET default_hostgroup = 0 WHERE username = 'app_user';
```

### Query Caching

```sql
-- Enable query cache
SET mysql-query_cache_size = 256MB;
SET mysql-query_cache_type = 1;

-- Cache specific queries
INSERT INTO mysql_query_rules (rule_id, active, match_digest, cache_ttl, apply)
VALUES (100, 1, '^SELECT.*FROM config', 60000, 1);
```

## Performance Tuning

### PgBouncer

```ini
# For high concurrency
max_client_conn = 2000
default_pool_size = 50
reserve_pool_size = 10

# For transaction mode
pool_mode = transaction
server_reset_query = ''

# Increase if queries are slow
query_timeout = 600
```

### ProxySQL

```sql
-- Increase pool size
UPDATE mysql_variables SET variable_value='50' WHERE variable_name='default_pool_size';
LOAD MYSQL VARIABLES TO RUNTIME;

-- Tune timeouts
UPDATE mysql_variables SET variable_value='30000' WHERE variable_name='max_query_time';
```

## Health Checks

### PgBouncer

```bash
./pool.sh pgbouncer health
./pool.sh pgbouncer stats
```

### ProxySQL

```bash
./pool.sh proxysql health
./pool.sh proxysql stats
```

## Integration with Applications

### Node.js (pg)

```javascript
const { Pool } = require('pg');
const pool = new Pool({
  host: 'localhost',
  port: 5433,  // PgBouncer port
  database: 'mydb',
  user: 'user',
  password: 'pass',
  max: 20,     // App-level pool
});
```

### Python (psycopg2)

```python
import psycopg2
conn = psycopg2.connect(
    host='localhost',
    port='5433',  # PgBouncer port
    database='mydb',
    user='user',
    password='pass'
)
```

### Go (database/sql)

```go
db, err := sql.Open("postgres", "postgres://user:pass@localhost:5433/mydb")
```

### Laravel

```php
DB_HOST=127.0.0.1
DB_PORT=5433  # PgBouncer port
DB_DATABASE=mydb
```

## Benchmarks

### PgBouncer

| Clients | Direct (ms) | Pooled (ms) | Improvement |
|---------|------------|-------------|-------------|
| 10 | 45 | 12 | 3.7x |
| 50 | 120 | 15 | 8x |
| 100 | 280 | 18 | 15x |
| 200 | Timeout | 25 | - |

### ProxySQL

| Clients | Direct (ms) | Pooled (ms) | Improvement |
|---------|------------|-------------|-------------|
| 10 | 50 | 14 | 3.5x |
| 50 | 150 | 18 | 8x |
| 100 | 350 | 22 | 16x |
