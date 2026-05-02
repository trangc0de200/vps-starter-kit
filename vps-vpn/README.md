# VPS VPN - WireGuard

Secure VPN server using WireGuard for encrypted remote access and site-to-site connections.

## Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                          WIREGUARD VPN                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐       │
│  │    Mobile    │────▶│             │     │   Internet   │       │
│  │   (iOS/Android)   │             │     │  (via VPN)   │       │
│  └──────────────┘     │  WireGuard  │────▶│              │       │
│                       │   Server    │     └──────────────┘       │
│  ┌──────────────┐     │   :51820   │                            │
│  │    Laptop    │────▶│             │     ┌──────────────┐     │
│  │   (macOS/Windows/Linux)    │             │     │   VPS LAN   │     │
│  └──────────────┘     │  wg-easy   │     └──────────────┘     │
│                       │  Web UI     │                            │
│  ┌──────────────┐     │  :51821    │                            │
│  │   Desktop    │────▶│             │                            │
│  └──────────────┘     └──────────────┘                            │
│                                                                      │
│                    VPN Network: 10.0.0.0/24                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Features

- **WireGuard Protocol**: Modern, fast, and secure VPN
- **wg-easy Web UI**: Easy management via browser
- **QR Code Generation**: Quick mobile client setup
- **Auto-IPv6**: IPv6 support
- **Kill Switch**: Block traffic when VPN disconnects
- **Split Tunnel**: Route specific traffic through VPN
- **Multi-client**: Support unlimited concurrent clients

## Quick Start

### 1. Configure

```bash
cd vps-vpn
cp .env.example .env
nano .env
```

### 2. Setup Environment

```bash
# Required settings
WG_HOST=your-vps-ip-or-domain.com
WEBUI_PASSWORD=your_secure_password

# Optional (defaults shown)
WG_PORT=51820
WG_NETWORK=10.0.0
WG_SUBNET=24
WG_DNS=1.1.1.1,1.0.0.1
```

### 3. Start VPN

```bash
docker-compose up -d
```

### 4. Access Web UI

- URL: `http://your-vps-ip:51821`
- Username: `admin`
- Password: `your WEBUI_PASSWORD`

## Client Apps

| Platform | App | Download |
|----------|-----|----------|
| iOS | WireGuard | App Store |
| Android | WireGuard | Play Store |
| macOS | WireGuard | App Store |
| Windows | WireGuard | [Official](https://www.wireguard.com/install/) |
| Linux | WireGuard | Package manager |
| Ubuntu/Debian | `apt install wireguard` | - |
| Fedora | `dnf install wireguard-tools` | - |

## CLI Management

### Add Client

```bash
# Add new client
./wg.sh add-client my-laptop

# Add with custom IP
./wg.sh add-client my-phone --ip 10.0.0.5
```

### List Clients

```bash
./wg.sh list
```

### Remove Client

```bash
./wg.sh remove-client my-laptop
```

### Show QR Code

```bash
./wg.sh qr my-laptop
```

### Restart VPN

```bash
./wg.sh restart
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WG_HOST` | - | **Required**: Your VPS IP or domain |
| `WG_PORT` | 51820 | WireGuard UDP port |
| `WG_NETWORK` | 10.0.0 | VPN network base |
| `WG_SUBNET` | 24 | VPN subnet mask |
| `WG_DNS` | 1.1.1.1,1.0.0.1 | DNS servers |
| `WG_ALLOWED` | 0.0.0.0/0,::/0 | Allowed IPs (0.0.0.0/0 = all traffic) |
| `WG_MTU` | 1420 | MTU size |
| `WEBUI_PORT` | 51821 | Web UI port |
| `WEBUI_PASSWORD` | - | **Required**: Web UI password |
| `WG_PERSISTENT_KEEPALIVE` | 25 | Keepalive interval (seconds) |

### Advanced Configuration

See [CONFIG.md](CONFIG.md) for advanced settings.

## Network Options

### Full Tunnel (Default)

All traffic routes through VPN:

```bash
WG_ALLOWED=0.0.0.0/0,::/0
```

### Split Tunnel

Only specified traffic routes through VPN:

```bash
# Only route specific subnets
WG_ALLOWED=10.0.0.0/8,192.168.1.0/24

# Route corporate traffic only
WG_ALLOWED=10.0.0.0/8
```

### Kill Switch

Block internet if VPN disconnects:

```bash
# Add to WG_POST_UP
iptables -A FORWARD -i wg0 -j ACCEPT
iptables -A FORWARD -o wg0 -j ACCEPT
iptables -A FORWARD -j DROP

# Add to WG_POST_DOWN
iptables -D FORWARD -i wg0 -j ACCEPT
iptables -D FORWARD -o wg0 -j ACCEPT
iptables -D FORWARD -j DROP
```

## DNS Settings

### Privacy DNS

```bash
WG_DNS=1.1.1.1,1.0.0.1        # Cloudflare
WG_DNS=8.8.8.8,8.8.4.4        # Google
WG_DNS=9.9.9.9,149.112.112.112 # Quad9
```

### Family-friendly DNS

```bash
WG_DNS=94.247.22.2,94.247.22.3  # Cleanbrowsing
```

### Ad-blocking DNS

```bash
WG_DNS=94.140.14.14,94.140.15.15  # AdGuard
```

## Client Configuration

### Manual Setup

1. Download config from Web UI
2. Import to WireGuard app
3. Or scan QR code

### Config File Format

```ini
[Interface]
PrivateKey = <your-private-key>
Address = 10.0.0.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = <server-public-key>
Endpoint = your-vps-ip:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

## Port Reference

| Port | Protocol | Service |
|------|----------|---------|
| 51820 | UDP | WireGuard |
| 51821 | TCP | Web UI |

## Firewall

### UFW

```bash
# Allow WireGuard
ufw allow 51820/udp

# Allow Web UI
ufw allow 51821/tcp

# Enable forwarding
ufw allow 51820,51821/tcp
```

### iptables

```bash
# Allow WireGuard
iptables -A INPUT -p udp --dport 51820 -j ACCEPT

# Allow Web UI
iptables -A INPUT -p tcp --dport 51821 -j ACCEPT

# NAT for VPN clients
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues.

### Connection Issues

```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs -f

# Check WireGuard status
docker exec wireguard wg show
```

### Slow Speed

1. Check server resources: `htop`
2. Try different DNS servers
3. Adjust MTU: `WG_MTU=1400`
4. Check network latency

### DNS Not Working

```bash
# Add to client config
[Interface]
DNS = 1.1.1.1
```

## Security

### Best Practices

1. **Use strong passwords** for Web UI
2. **Rotate keys regularly**
3. **Enable 2FA** on Web UI (planned)
4. **Use split tunnel** when possible
5. **Monitor logs** for unauthorized access

### Recommended Settings

```bash
WG_PORT=51820                    # Default port
WG_ALLOWED=0.0.0.0/0           # Full tunnel
WG_PERSISTENT_KEEPALIVE=25       # Keep connection alive
WG_MTU=1420                      # Standard MTU
```

## Backup

### Backup Configuration

```bash
# Backup WireGuard config
tar -czf wireguard-backup.tar.gz config/

# Restore
tar -xzf wireguard-backup.tar.gz
```

## Documentation

- [Configuration](CONFIG.md)
- [Client Setup](CLIENTS.md)
- [Troubleshooting](TROUBLESHOOTING.md)
