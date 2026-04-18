# Security Notes

This starter kit follows a practical baseline security model.

## Recommended Public Ports
- 22/tcp for SSH
- 80/tcp for HTTP
- 443/tcp for HTTPS
- 81/tcp only if you intentionally expose the Nginx Proxy Manager admin UI

## Recommended Rules
- use SSH keys only
- disable root SSH login
- disable SSH password authentication
- keep databases private
- use strong passwords
- enable UFW
- enable Fail2Ban
- protect internal admin tools using NPM Access Lists
