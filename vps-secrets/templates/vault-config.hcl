# Vault Configuration Template

# ===========================================
# HashiCorp Vault Configuration
# ===========================================

# Storage
storage "raft" {
  path = "/vault/data"
  node_id = "node1"
}

# Listener
listener "tcp" {
  address     = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_disable = "true"  # Enable TLS in production
}

# High Availability
cluster_addr = "https://127.0.0.1:8201"

# API Address
api_addr = "https://127.0.0.1:8200"

# Disable Memory Lock
disable_mlock = true  # Required for Docker

# Telemetry
telemetry {
  prometheus_retention_time = "30s"
  disable_hostname = true
}

# Max Lease TTL
max_lease_ttl = "768h"  # 32 days

# Default Lease TTL
default_lease_ttl = "768h"

# UI
ui = true
