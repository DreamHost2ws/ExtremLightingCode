#!/bin/bash

set -e

echo "Detecting OS..."

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    CODENAME=$VERSION_CODENAME
else
    echo "Cannot detect OS."
    exit 1
fi

echo "Detected: $OS ($CODENAME)"

apt update && apt upgrade -y

apt install -y software-properties-common curl ca-certificates gnupg lsb-release apt-transport-https

# Add universe repo only if Ubuntu
if [ "$OS" = "ubuntu" ]; then
    add-apt-repository -y universe
fi

# Add Sury PHP repository (works for both Ubuntu & Debian)
curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/php.gpg

echo "deb [signed-by=/usr/share/keyrings/php.gpg] https://packages.sury.org/php/ $CODENAME main" \
> /etc/apt/sources.list.d/php.list

apt update

apt install -y \
php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,redis} \
mariadb-server nginx redis-server \
tar unzip zip git make dos2unix cron openssl screen

systemctl enable --now nginx
systemctl enable --now mariadb
systemctl enable --now redis-server
systemctl enable --now cron
systemctl enable --now php8.3-fpm

echo "Installation complete."
