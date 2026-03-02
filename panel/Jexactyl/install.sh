#!/bin/bash
set -e

echo "=== AUTO OS DETECT INSTALLER ==="
read -p "🌐 Enter domain (panel.example.com): " DOMAIN

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "❌ OS detect failed"
    exit 1
fi

echo "Detected OS: $OS $VER"

# Update system
apt update -y
apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release

# Add PHP PPA (Ubuntu only)
if [[ "$OS" == "ubuntu" ]]; then
    echo "Adding PHP Ondrej PPA..."
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
else
    echo "Skipping PHP PPA (Debian detected)"
fi

# Redis repo (Ubuntu & Debian)
echo "Adding Redis repo..."
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/redis.list

# MariaDB repo (Skip Ubuntu 22+)
if [[ "$OS" == "ubuntu" && $(echo "$VER >= 22.04" | bc -l) -eq 1 ]]; then
    echo "Skipping MariaDB repo (Ubuntu 22+ already supported)"
else
    echo "Adding MariaDB repo..."
    curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash
fi

# Update repos again
apt update -y

# Install packages
echo "Installing PHP 8.1 + Nginx + MariaDB + Redis..."
apt install -y \
php8.1 php8.1-{cli,gd,mysql,pdo,mbstring,tokenizer,bcmath,xml,fpm,curl,zip} \
mariadb-server nginx tar unzip git redis

# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Enable services
systemctl enable --now nginx mariadb redis-server php8.1-fpm

mkdir -p /var/www/jexactyl
cd /var/www/jexactyl
curl -Lo panel.tar.gz https://github.com/jexactyl/jexactyl/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

DB_NAME=jexactyl
DB_USER=jexactyl
DB_PASS=jexactyl
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "CREATE DATABASE ${DB_NAME};"
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"

cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
if ! grep -q "^APP_ENVIRONMENT_ONLY=" .env; then
    echo "APP_ENVIRONMENT_ONLY=false" >> .env
fi
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
php artisan key:generate --force
php artisan migrate --seed --force
chown -R www-data:www-data /var/www/jexactyl/*
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/jexactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
mkdir -p /etc/certs/jx
cd /etc/certs/jx
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
-keyout privkey.pem -out fullchain.pem

tee /etc/nginx/sites-available/panel.conf > /dev/null <<'EOF'
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/jexactyl/public;
    index index.php index.html;

    access_log /var/log/nginx/jexactyl.app-access.log;
    error_log  /var/log/nginx/jexactyl.app-error.log warn;

    # Upload & runtime limits
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/certs/jx/fullchain.pem;
    ssl_certificate_key /etc/certs/jx/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # Security Headers
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy strict-origin-when-cross-origin;
    add_header Content-Security-Policy "frame-ancestors 'self'";

    # Main routing
    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # PHP Processing
    location ~ \.php$ {
        include fastcgi_params;

        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";

        # PHP limits
        fastcgi_param PHP_VALUE "upload_max_filesize=100M post_max_size=100M memory_limit=512M max_execution_time=300";

        # Performance tuning
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 32k;
        fastcgi_buffers 8 32k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    # Deny hidden files
    location ~ /\.(?!well-known).* {
        deny all;
    }

    # Cache static assets
    location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        access_log off;
        add_header Cache-Control "public, no-transform";
    }
}
EOF

ln -sf /etc/nginx/sites-available/panel.conf /etc/nginx/sites-enabled/panel.conf
nginx -t && systemctl restart nginx


# --- Queue Worker ---
tee /etc/systemd/system/panel.service > /dev/null << 'EOF'
# Jexactyl Queue Worker File
# ----------------------------------

[Unit]
Description=Jexactyl Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/jexactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now panel.service
clear
# --- Admin User ---
cd /var/www/jexactyl
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env
php artisan p:user:make


