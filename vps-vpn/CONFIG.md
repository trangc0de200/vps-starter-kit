# WireGuard Configuration

Advanced configuration options for VPS VPN.

## Server Configuration

### Full Configuration Example

```yaml
# docker-compose.yml
services:
  wg-easy:
    image: ghcr.io/wg-easy/wg-easy:latest
    environment:
      WG_HOST: vpn.example.com
      WG_PORT: 51820
      WG_NETWORK: 10.0.0
      WG_SUBNET: 24
      WG_ADDRESS: 10.0.0.1/24
      WG_DNS: 1.1.1.1,1.0.0.1
      WG_ALLOWED: 0.0.0.0/0,::/0
      WG_MTU: 1420
      WG_PERSISTENT_KEEPALIVE: 25
      WG_PRE_UP: "echo 'Pre up'"
      WG_POST_UP: |
        iptables -A FORWARD -i wg0 -j ACCEPT
        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
      WG_POST_DOWN: |
        iptables -D FORWARD -i wg0 -j ACCEPT
        iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
      WG_DEFAULT_ADDRESS: 10.0.0.2
      WG_ALLOWED_IPS: 0.0.0.0/0,::/0
      WEBUI_PORT: 51821
      WEBUI_PASSWORD: your_secure_password
      PASSWORD_HASH: ""  # bcrypt hash (optional)
```

## Network Configuration

### Single Client IP Assignment

```bash
# First client gets .2, second gets .3, etc.
WG_DEFAULT_ADDRESS=10.0.0.2
```

### Custom Network Range

```bash
WG_NETWORK=10.8.0           # Use 10.8.0.x
WG_SUBNET=24                # /24 subnet
WG_ADDRESS=10.8.0.1/24
```

### Multi-site VPN

Connect multiple VPS locations:

```bash
# Site A (10.0.0.x)
WG_NETWORK=10.0.0
WG_ALLOWED=10.0.0.0/24,10.1.0.0/24

# Site B (10.1.0.x)
WG_NETWORK=10.1.0
WG_ALLOWED=10.0.0.0/24,10.1.0.0/24
```

## Routing

### Route All Traffic

```bash
WG_ALLOWED=0.0.0.0/0,::/0
```

### Route Only Private Networks

```bash
WG_ALLOWED=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

### Route Specific Subnet

```bash
# Only route through VPN for specific subnet
WG_ALLOWED=192.168.1.0/24
```

### Exclude Local Network

On client side, exclude local LAN from VPN:

```ini
[Peer]
AllowedIPs = 0.0.0.0/0,192.168.1.0/24
```

This routes all traffic except 192.168.1.x through VPN.

## DNS Configuration

### Cloudflare (Default)

```bash
WG_DNS=1.1.1.1,1.0.0.1
```

### Google

```bash
WG_DNS=8.8.8.8,8.8.4.4
```

### Quad9 (Privacy)

```bash
WG_DNS=9.9.9.9,149.112.112.112
```

### Custom DNS

```bash
# Your own DNS server
WG_DNS=10.0.0.53

# Multiple DNS
WG_DNS=10.0.0.53,1.1.1.1
```

## Performance Tuning

### MTU

```bash
# Standard (usually works)
WG_MTU=1420

# Lower for unstable connections
WG_MTU=1400

# PPPoE connections
WG_MTU=1380
```

### Keepalive

```bash
# 25 seconds (default, good for NAT)
WG_PERSISTENT_KEEPALIVE=25

# Disable for static connections
WG_PERSISTENT_KEEPALIVE=0

# More frequent for mobile
WG_PERSISTENT_KEEPALIVE=15
```

## Firewall Rules

### iptables NAT

```bash
WG_POST_UP=iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

### With Logging

```bash
WG_POST_UP=iptables -A FORWARD -i wg0 -j ACCEPT -m limit --limit 5/min -j LOG --log-prefix "WireGuard FORWARD: "
```

### With Connection Limits

```bash
WG_POST_UP=iptables -A FORWARD -i wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -A FORWARD -i wg0 -m connlimit --connlimit-above 100 -j DROP
```

## IPv6

### Enable IPv6

```bash
WG_ALLOWED=0.0.0.0/0,::/0
```

### IPv6 Only

```bash
WG_ALLOWED=::/0
```

### Disable IPv6

```bash
WG_ALLOWED=0.0.0.0/0
```

## Security Hardening

### Disable Web UI Password Hash

```bash
# Generate bcrypt hash
PASSWORD_HASH=$(htpasswd -bnBC 10 "" yourpassword | tr -d ':\n')

# Use hash instead of plain password
PASSWORD_HASH=$PASSWORD_HASH
WEBUI_PASSWORD=""
```

### Restrict Interface Binding

```bash
# Bind to specific interface
WG_POST_UP=ip link add dev wg0 type wireguard; ip link set wg0 up
```

### Rate Limiting

```bash
WG_POST_UP=iptables -A INPUT -p udp --dport 51820 -m hashlimit --hashlimit-above 10/sec --hashlimit-burst 20 -j DROP
```

## Docker Network

### Custom Network

```yaml
networks:
  vpn_network:
    name: vpn_network
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/24
```

### Host Network (Required)

WireGuard requires host network mode:

```yaml
network_mode: host
```

## Monitoring

### Prometheus Metrics

Add to `WG_POST_UP`:

```bash
WG_POST_UP=echo "wg0 up" > /tmp/wireguard_status
```

### Log Analysis

```bash
# View connection logs
docker-compose logs | grep -i "peer\|client"

# Monitor active connections
docker exec wireguard wg show

# Show transfer stats
docker exec wireguard wg show wg0 transfer
```

## Backup Configuration

### Manual Backup

```bash
# Backup config directory
tar -czf wg-backup-$(date +%Y%m%d).tar.gz config/

# Backup specific client
cat config/wg0.json | jq '.clients[] | select(.name == "my-client")'
```

### Restore

```bash
# Stop container
docker-compose down

# Restore config
tar -xzf wg-backup-20240101.tar.gz

# Start container
docker-compose up -d
```

## Kubernetes

### Pod Definition

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wireguard
spec:
  hostNetwork: true
  containers:
  - name: wg-easy
    image: ghcr.io/wg-easy/wg-easy:latest
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - SYS_MODULE
    env:
    - name: WG_HOST
      value: "vpn.example.com"
    - name: WG_PORT
      value: "51820"
    - name: WEBUI_PASSWORD
      valueFrom:
        secretKeyRef:
          name: wireguard-secrets
          key: password
    volumeMounts:
    - name: config
      mountPath: /app/config
    - name: modules
      mountPath: /lib/modules
      readOnly: true
  volumes:
  - name: config
    persistentVolumeClaim:
      claimName: wireguard-config
  - name: modules
    hostPath:
      path: /lib/modules
```

## Troubleshooting Config

### Port Already in Use

```bash
# Check what's using the port
netstat -ulnp | grep 51820

# Change port
WG_PORT=51821
```

### Interface Not Created

```bash
# Load kernel module
modprobe wireguard

# Check module
lsmod | grep wireguard
```

### DNS Not Resolving

```bash
# Add DNS to client config manually
[Interface]
DNS = 1.1.1.1

# Or use dnsmasq
apt install dnsmasq
```
