# Client Setup

Detailed guide for setting up WireGuard clients on different platforms.

## Web UI Setup

### Access Web UI

1. Open browser: `http://your-vps-ip:51821`
2. Login with admin credentials
3. Click "Create Client"

### Create New Client

1. Enter client name (e.g., "my-phone")
2. Click "Generate"
3. Download config or scan QR code

## Mobile Setup

### iOS (iPhone/iPad)

1. Download **WireGuard** from App Store
2. Open app
3. Tap **+** button
4. Choose **Create from QR code**
5. Scan QR code from Web UI
6. Tap **Allow** for VPN permission
7. Toggle VPN on

### Android

1. Download **WireGuard** from Play Store
2. Open app
3. Tap **+** button
4. Choose **Scan from QR code**
5. Scan QR code from Web UI
6. Tap **Activate** to connect

### Manual Mobile Setup

If QR code not available:

1. Download config from Web UI
2. Save as `.conf` file
3. Share to device (email, AirDrop, etc.)
4. Open file with WireGuard app
5. Import configuration

## Desktop Setup

### Windows

1. Download WireGuard from [official site](https://www.wireguard.com/install/)
2. Install and open
3. Click **Import tunnel(s) from file**
4. Select downloaded config
5. Click **Activate**

### macOS

1. Download from App Store: **WireGuard**
2. Open app
3. Click **+** button
4. Choose **Import tunnel(s) from file...**
5. Select config
6. Toggle on

### Linux (Ubuntu/Debian)

```bash
# Install
sudo apt install wireguard

# Generate key pair (on client)
wg genkey | tee privatekey | wg pubkey > publickey

# Create config
sudo nano /etc/wireguard/wg0.conf
```

### Linux Config

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

```bash
# Start VPN
sudo wg-quick up wg0

# Stop VPN
sudo wg-quick down wg0

# Enable on boot
sudo systemctl enable wg-quick@wg0
```

### Fedora/RHEL

```bash
# Install
sudo dnf install wireguard-tools

# Create config in /etc/wireguard/
sudo wg-quick up wg0
```

## Manual Config File

### Template

```ini
[Interface]
# Client private key
PrivateKey = <CLIENT_PRIVATE_KEY>
# VPN IP address
Address = 10.0.0.2/32
# DNS servers
DNS = 1.1.1.1

[Peer]
# Server public key
PublicKey = <SERVER_PUBLIC_KEY>
# Server address and port
Endpoint = vpn.example.com:51820
# Routes (0.0.0.0/0 = all traffic)
AllowedIPs = 0.0.0.0/0
# Keep connection alive
PersistentKeepalive = 25
```

### Split Tunnel Config

Route only specific traffic:

```ini
[Interface]
PrivateKey = <CLIENT_PRIVATE_KEY>
Address = 10.0.0.2/32

[Peer]
PublicKey = <SERVER_PUBLIC_KEY>
Endpoint = vpn.example.com:51820
# Only route 10.x networks through VPN
AllowedIPs = 10.0.0.0/8,192.168.1.0/24
PersistentKeepalive = 25
```

## Client Commands

### Show Connection Status

```bash
# Linux/macOS
sudo wg show

# Windows - use GUI
```

### Check Active Peers

```bash
sudo wg show wg0
```

## Multiple Clients

### Connect Multiple Devices

Each device needs its own config:

1. Add new client in Web UI
2. Download config
3. Import to device
4. Each gets unique VPN IP

### IP Assignment

| Client | VPN IP |
|--------|--------|
| Phone | 10.0.0.2 |
| Laptop | 10.0.0.3 |
| Desktop | 10.0.0.4 |

## Troubleshooting

### Connection Timeout

1. Check internet connection
2. Verify VPN server is running
3. Check firewall rules
4. Try different DNS servers

### Slow Speed

1. Check server resources
2. Try different DNS
3. Adjust MTU
4. Check network latency

### DNS Not Working

Add DNS manually in config:

```ini
[Interface]
DNS = 1.1.1.1
```

### Cannot Access Local Network

Exclude local network from VPN:

```ini
[Peer]
AllowedIPs = 0.0.0.0/0,192.168.1.0/24
```

## Security Tips

1. **Never share config files** - contains private key
2. **Use unique keys** for each client
3. **Rotate keys** periodically
4. **Enable Kill Switch** when available
5. **Verify server fingerprint** on first connect

## Keyboard Shortcuts (Linux)

| Command | Description |
|---------|-------------|
| `sudo wg-quick up wg0` | Connect |
| `sudo wg-quick down wg0` | Disconnect |
| `sudo wg show` | Show status |
| `sudo systemctl status wg-quick@wg0` | Check service |
