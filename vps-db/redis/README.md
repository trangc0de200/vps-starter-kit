# Redis Database

## Overview

Production-ready Redis deployment with persistence, clustering support, and SSL.

## Features

- **Redis 7.x** latest stable
- **AOF/RDB persistence** for data durability
- **SSL/TLS** encryption support
- **Prometheus metrics** via redis_exporter
- **Authentication** and ACL support
- **Memory optimization** with eviction policies

## Quick Start

```bash
cd vps-db/redis
cp .env.example .env
# Edit .env with your configuration

docker-compose up -d

# Verify
docker exec redis redis-cli ping
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_VERSION` | 7.2-alpine | Redis image version |
| `REDIS_PASSWORD` | - | Redis password (required) |
| `REDIS_MAXMEMORY` | 256mb | Max memory usage |
| `REDIS_MAXMEMORY_POLICY` | allkeys-lru | Eviction policy |
| `REDIS_DATABASES` | 16 | Number of databases |

### Eviction Policies

| Policy | Description |
|--------|-------------|
| `noeviction` | Return error on write |
| `allkeys-lru` | Evict least recently used keys |
| `allkeys-lfu` | Evict least frequently used keys |
| `volatile-lru` | Evict LRU only in expire set |
| `allkeys-random` | Evict random keys |

## Persistence

### RDB (Snapshotting)

```bash
# Automatic snapshots
REDIS_SAVE="900 1 300 10 60 10000"
# Save every 900 sec if at least 1 key changed
# Save every 300 sec if at least 10 keys changed
# Save every 60 sec if at least 10000 keys changed
```

### AOF (Append Only File)

```bash
REDIS_APPENDONLY=yes
REDIS_APPENDFSYNC=everysec  # everysec, always, no
```

## Replication

### Master-Slave Setup

```bash
# On replica
REDIS_REPLICAOF=master 6379
```

### Redis Sentinel (HA)

See [Redis Sentinel](ha/sentinel/) for high availability setup.

## Clustering

For Redis Cluster:

```bash
REDIS_CLUSTER_ENABLED=yes
REDIS_CLUSTER_REPLICAS=1
```

## Monitoring

### Prometheus Metrics

Access metrics at `redis:9121/metrics`:

```bash
docker exec redis wget -O- http://localhost:9121/metrics
```

### Key Metrics

- `redis_memory_used_bytes` - Memory used
- `redis_keys_total` - Total keys
- `redis_connected_clients` - Active clients
- `redis_commands_total` - Commands executed
- `redis_hits_total` - Key hits
- `redis_misses_total` - Key misses
- `redis_hit_rate` - Cache hit rate

### Redis INFO

```bash
docker exec redis redis-cli info
docker exec redis redis-cli info server
docker exec redis redis-cli info stats
docker exec redis redis-cli info memory
docker exec redis redis-cli info replication
```

## Backup

### Manual Backup

```bash
# BGSAVE and copy RDB
docker exec redis redis-cli BGSAVE
docker exec redis cat /data/dump.rdb > backup.rdb

# Copy AOF
docker cp redis:/data/appendonly.aof backup.aof
```

### Automated Backup

Backups run via cron with retention.

```bash
# View backup logs
tail -f backups/backup.log

# List backups
ls -la backups/
```

## Redis Commander (Optional)

Web UI for Redis management:

```yaml
# Add to docker-compose.yml
redis-commander:
  image: rediscommander/redis-commander:latest
  environment:
    - REDIS_HOSTS=local:redis:6379
  ports:
    - "8081:8081"
  profiles:
    - ui
```

## PHPRedisAdmin (Optional)

Web UI for Redis:

```yaml
phpRedisAdmin:
  image: erikdubbelboer/phpredisadmin:latest
  environment:
    - REDIS_HOST=redis
  ports:
    - "8082:80"
  profiles:
    - ui
```

## Clients

### Python

```python
import redis

r = redis.Redis(
    host='localhost',
    port=6379,
    password='your_password',
    decode_responses=True
)

# Test
r.ping()

# Set/Get
r.set('key', 'value')
r.get('key')
```

### Node.js

```javascript
const redis = require('redis');

const client = redis.createClient({
    socket: {
        host: 'localhost',
        port: 6379
    },
    password: 'your_password'
});

await client.connect();
await client.ping();
```

### PHP

```php
$redis = new Redis();
$redis->connect('localhost', 6379);
$redis->auth('your_password');
$redis->set('key', 'value');
```

## Security

### ACL Configuration

```bash
# Create user with limited permissions
redis-cli ACL SETUSER reader on >password ~cached:* -@read

# Create admin user
redis-cli ACL SETUSER admin on >adminpass ~* +@all
```

### SSL/TLS

```bash
# Enable TLS
REDIS_TLS_ENABLED=yes
REDIS_TLS_CERT=/certs/redis.crt
REDIS_TLS_KEY=/certs/redis.key
REDIS_TLS_CA=/certs/ca.crt
```
