# App Template

Đây là template tối thiểu để khởi tạo một app mới trong starter kit.

## Cách dùng

```bash
cp -r /opt/vps/vps-app/app-template /opt/vps/vps-app/my-app
cd /opt/vps/vps-app/my-app
cp .env.production.example .env.production
nano .env.production
```

Sau đó sửa:
- `docker-compose.yml`
- `scripts/migrate.sh`
- `scripts/healthcheck.sh`
- `scripts/rollback.sh`

cho đúng framework của app bạn.
