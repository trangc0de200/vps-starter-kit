# VPS Starter Kit Repo Template

Một bộ khung **production-ready** để bootstrap VPS Ubuntu 24.04 cho stack Docker một cách nhất quán.

Repo này được thiết kế để bạn chỉ cần:

1. mua VPS mới
2. upload hoặc `git clone` repo này lên VPS
3. chạy `sudo ./install.sh`
4. vào các thư mục `vps-infra`, `vps-db`, `vps-app` để bật các service cần dùng

## Cấu trúc repo

```text
vps-starter-kit/
├── install.sh
├── README.md
├── .github/
│   └── workflows/
├── vps-app/
│   └── app-template/
├── vps-db/
│   ├── postgres/
│   ├── mysql/
│   ├── redis/
│   └── sqlserver/
└── vps-infra/
    ├── nginx-proxy-manager/
    └── shared/
```

## install.sh sẽ làm gì

- update và upgrade Ubuntu 24.04
- cài package nền tảng
- cài Docker Engine + Docker Compose plugin
- bật Docker on boot
- tạo user deploy
- thêm user deploy vào group `sudo` và `docker`
- bật UFW
- bật Fail2Ban
- tạo cấu trúc thư mục chuẩn trong máy
- tạo shared Docker networks:
  - `proxy_network`
  - `db_network`
- scaffold sẵn Nginx Proxy Manager
- copy toàn bộ template trong repo này sang thư mục đích trên VPS

## Cách dùng nhanh

```bash
chmod +x install.sh
sudo ./install.sh
```

Hoặc truyền biến môi trường:

```bash
sudo BOOTSTRAP_USER=deployer          VPS_ROOT=/opt/vps          INSTALL_NPM=yes          ENABLE_UFW=yes          ENABLE_FAIL2BAN=yes          TZ_VALUE=UTC          ./install.sh
```

## Sau khi chạy xong

### 1. Chuyển sang deploy user

```bash
su - deployer
```

### 2. Start Nginx Proxy Manager

```bash
cd /opt/vps/vps-infra/nginx-proxy-manager
docker compose up -d
```

Admin UI mặc định:

```text
http://YOUR_SERVER_IP:81
```

### 3. Start database nào cần dùng

PostgreSQL:

```bash
cd /opt/vps/vps-db/postgres
cp .env.example .env
nano .env
docker compose up -d
```

MySQL:

```bash
cd /opt/vps/vps-db/mysql
cp .env.example .env
nano .env
docker compose up -d
```

Redis:

```bash
cd /opt/vps/vps-db/redis
cp .env.example .env
nano .env
nano redis.conf
docker compose up -d
```

SQL Server:

```bash
cd /opt/vps/vps-db/sqlserver
cp .env.example .env
nano .env
docker compose up -d
```

### 4. Tạo app mới từ template

```bash
cp -r /opt/vps/vps-app/app-template /opt/vps/vps-app/my-app
cd /opt/vps/vps-app/my-app
cp .env.production.example .env.production
nano .env.production
```

## Quy ước mạng nội bộ

- app public gắn vào `proxy_network`
- database/cache gắn vào `db_network`
- app nào cần DB thì gắn cả 2 network nếu cần

## Các thư mục chính trên VPS sau bootstrap

```text
/opt/vps/
├── backups/
├── vps-app/
├── vps-db/
└── vps-infra/
```

## Gợi ý vận hành production

- luôn đổi password mặc định
- không public DB ports nếu không thực sự cần
- dùng Nginx Proxy Manager Access Lists cho pgAdmin/Adminer/Portainer
- chạy backup script bằng cron
- dùng GitHub Actions để deploy app
- test restore định kỳ, không chỉ backup

## File quan trọng

- `install.sh`: bootstrap từ đầu
- `vps-infra/nginx-proxy-manager/docker-compose.yml`: reverse proxy layer
- `vps-db/*`: template DB/cache
- `vps-app/app-template/*`: template deploy app Docker
- `.github/workflows/deploy-reusable.yml`: workflow deploy mẫu

## Ghi chú

Repo này không ép buộc 1 framework cụ thể. Nó đóng vai trò **starter kit hạ tầng** để bạn tái sử dụng cho mọi project.
