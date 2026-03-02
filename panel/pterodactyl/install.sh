#!/bin/bash

# ==========================================
#  LPSTYLE PTERODACTYL AUTO DEPLOY v3
# ==========================================

# -------- COLORS --------
RESET="\e[0m"
RED="\e[1;31m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
PURPLE="\e[1;35m"
CYAN="\e[1;36m"
WHITE="\e[1;37m"
GRAY="\e[1;90m"

line(){ echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"; }
step(){ echo -e "${BLUE}➜ $1${RESET}"; }
ok(){ echo -e "${GREEN}✔ $1${RESET}"; }
warn(){ echo -e "${YELLOW}⚠ $1${RESET}"; }
fail(){ echo -e "${RED}✖ $1${RESET}"; }

# -------- EFFECTS --------

type_write() {
    text="$1"
    delay=0.01
    for (( i=0; i<${#text}; i++ )); do
        echo -ne "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

loading_bar() {
    echo -ne "${GREEN}[ SYSTEM ]${RESET} "
    for i in {1..20}; do
        echo -ne "█"
        sleep 0.03
    done
    echo -e " ${CYAN}ONLINE${RESET}"
}

deploy_bar() {
    echo -ne "${PURPLE}[ DEPLOY ]${RESET} "
    for i in {1..25}; do
        echo -ne "█"
        sleep 0.04
    done
    echo -e " ${GREEN}SUCCESS${RESET}"
}

# -------- HEADER --------
clear
echo -e "${CYAN}"

cat << "EOF"
8888888b.  888                                 888                   888             888 
888   Y88b 888                                 888                   888             888 
888    888 888                                 888                   888             888 
888   d88P 888888 .d88b.  888d888 .d88b.   .d88888  8888b.   .d8888b 888888 888  888 888 
8888888P"  888   d8P  Y8b 888P"  d88""88b d88" 888     "88b d88P"    888    888  888 888 
888        888   88888888 888    888  888 888  888 .d888888 888      888    888  888 888 
888        Y88b. Y8b.     888    Y88..88P Y88b 888 888  888 Y88b.    Y88b.  Y88b 888 888 
888         "Y888 "Y8888  888     "Y88P"   "Y88888 "Y888888  "Y8888P  "Y888  "Y88888 888 
                                                                                 888     
                                                                            Y8b d88P     
                                                                             "Y88P"      
EOF

echo -e "${RESET}"
line
echo -e "${GREEN}        :: PTERODACTYL AUTO DEPLOYMENT SYSTEM :: v3${RESET}"
line
echo ""

# -------- BOOT SEQUENCE --------
echo -ne "${BLUE}[KERNEL] ${RESET}"
type_write "Initializing core modules..."
echo -ne "${BLUE}[MEMORY] ${RESET}"
type_write "Allocating server resources..."
sleep 0.5
loading_bar
echo ""

# -------- DOMAIN INPUT LOOP --------
while true; do
    line
    echo -e "${CYAN}>> CONFIGURATION REQUIRED <<${RESET}"
    echo ""
    type_write "ENTER TARGET DOMAIN:"
    echo -ne "${GREEN} root@deploy:~$ ${RESET}"
    read DOMAIN
    DOMAIN=${DOMAIN:-panel.example.com}

    echo ""
    echo -e "${CYAN}>> TARGET ENTERED: ${WHITE}$DOMAIN${RESET}"
    echo -ne "${YELLOW}Confirm deployment? (y/n): ${RESET}"
    read CONFIRM

    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        echo ""
        ok "Target Locked: $DOMAIN"
        break
    elif [[ "$CONFIRM" == "n" || "$CONFIRM" == "N" ]]; then
        warn "Re-entering domain configuration..."
    else
        fail "Invalid choice. Use y or n."
    fi
done

echo ""
line
echo -e "${PURPLE}>> EXECUTING ROOT PROTOCOLS...${RESET}"
sleep 1

# Add your actual install logic below this line
step "Updating system packages..."
# --- Dependencies ---
apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release

# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

if [[ "$OS" == "ubuntu" ]]; then
    echo "✅ Detected Ubuntu. Adding PPA for PHP..."
    apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    echo "✅ Detected Debian. Skipping PPA and adding PHP repo manually..."
    # Add SURY PHP repo for Debian
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

# Add Redis GPG key and repo
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

apt update

# --- Install PHP + extensions ---
apt install -y php8.3 php8.3-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server
sleep 1
ok "System updated."
step "Installing dependencies..."
# --- Install Composer ---
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

# --- Download Pterodactyl Panel ---
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# --- MariaDB Setup ---
DB_NAME=panel
DB_USER=pterodactyl
DB_PASS=yourPassword
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "CREATE DATABASE ${DB_NAME};"
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"

# --- .env Setup ---
if [ ! -f ".env.example" ]; then
    curl -Lo .env.example https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
fi
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
if ! grep -q "^APP_ENVIRONMENT_ONLY=" .env; then
    echo "APP_ENVIRONMENT_ONLY=false" >> .env
fi

# --- Install PHP dependencies ---
echo "✅ Installing PHP dependencies..."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# --- Generate Application Key ---
echo "✅ Generating application key..."
php artisan key:generate --force

# --- Run Migrations ---
php artisan migrate --seed --force

# --- Permissions ---
chown -R www-data:www-data /var/www/pterodactyl/*
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -
sleep 1
ok "Dependencies installed."
step "Generating SSL certificate..."

# --- Nginx Setup ---
mkdir -p /etc/certs/panel
cd /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=NA/ST=NA/L=NA/O=NA/CN=Generic SSL Certificate" \
-keyout privkey.pem -out fullchain.pem
sleep 1
ok "SSL secured."
step "Configuring NGINX..."
sleep 1
tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf || true
nginx -t && systemctl restart nginx
ok "Nginx online"

# --- Queue Worker ---
tee /etc/systemd/system/pteroq.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now pteroq.service
ok "Queue running"
ok "NGINX configured."

clear
step "Create admin user"
deploy_bar
# --- Admin User ---
cd /var/www/pterodactyl
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env
php artisan p:user:make

# ---------------- DONE ----------------

echo ""
line
echo -e "${GREEN}🚀 Deployment Complete!${RESET}"
echo -e "${WHITE}Access your panel at:${RESET} ${CYAN}https://$DOMAIN${RESET}"
line
echo -e "${GRAY}SYSTEM STATUS: STABLE | FIREWALL: ACTIVE | DATABASE: CONNECTED${RESET}"
echo ""
