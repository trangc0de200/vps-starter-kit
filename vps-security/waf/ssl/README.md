# SSL Self-Signed Certificate Generation
# For production, use Let's Encrypt via Nginx Proxy Manager

# Generate self-signed certificate:
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#   -keyout ssl/key.pem \
#   -out ssl/cert.pem \
#   -subj "/C=US/ST=State/L=City/O=Organization/CN=yourdomain.com"

# Generate with SAN (Subject Alternative Name):
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#   -keyout ssl/key.pem \
#   -out ssl/cert.pem \
#   -subj "/C=US/ST=State/L=City/O=Organization/CN=yourdomain.com" \
#   -addext "subjectAltName=DNS:yourdomain.com,DNS:www.yourdomain.com,IP:YOUR_SERVER_IP"

# Certificate info:
# Cert: ssl/cert.pem
# Key:  ssl/key.pem
