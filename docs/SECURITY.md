# Security Guide

Recommended baseline:
- 22/tcp for SSH
- 80/tcp for HTTP
- 443/tcp for HTTPS
- 81/tcp only if you intentionally expose Nginx Proxy Manager admin UI

Important principles:
- keep databases private
- use SSH keys
- disable password auth only after confirming access
- protect monitoring and admin tools
