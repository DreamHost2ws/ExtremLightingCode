#!/bin/bash
# Jexactyl Auto Installer with OS Detection + Nobita Banner (Silent Mode)
set -e
export DEBIAN_FRONTEND=noninteractive

# Enhanced Colors for UI
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# UI Elements
BOLD='\033[1m'
UNDERLINE='\033[4m'

# Logging setup
log_file="/var/log/jexactyl-install.log"
exec > >(tee -a "$log_file") 2>&1

# Enhanced Progress display functions
print_header() {
    echo -e "${PURPLE}"
    echo -e "╔══════════════════════════════════════════════════════════════╗"
    echo -e "║${WHITE}           🦖 Jexactyl Auto Installer${PURPLE}                     ║"
    echo -e "║                 ${WHITE}With Enhanced UI${PURPLE}                      ║"
    echo -e "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_progress() {
    echo -e "${CYAN}${BOLD}[~]${NC} $1..."
}

show_success() {
    echo -e "${GREEN}${BOLD}[✓]${NC} $1"
}

show_warning() {
    echo -e "${YELLOW}${BOLD}[!]${NC} $1"
}

show_error() {
    echo -e "${RED}${BOLD}[✗]${NC} $1"
}

show_info() {
    echo -e "${BLUE}${BOLD}[i]${NC} $1"
}

# Function to show progress bar
progress_bar() {
    local duration=$1
    local steps=20
    local step_delay=$(echo "scale=3; $duration/$steps" | bc -l 2>/dev/null || echo "0.1")
    
    echo -ne "${BLUE}["
    for ((i=0; i<steps; i++)); do
        echo -ne "█"
        sleep $step_delay
    done
    echo -e "]${NC}"
}

# Function to animate text
animate_text() {
    local text=$1
    echo -ne "${CYAN}"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep 0.02
    done
    echo -e "${NC}"
}

# Error handling function
handle_error() {
    show_error "Error occurred in step: $1"
    echo -e "${YELLOW}📋 Check log file: $log_file${NC}"
    exit 1
}

# Silent command execution with progress
run_silent() {
    local step_name="$1"
    local command="$2"
    
    show_progress "$step_name"
    if eval "$command" > /dev/null 2>&1; then
        show_success "$step_name completed"
        return 0
    else
        handle_error "$step_name"
        return 1
    fi
}

# Clear and Display Enhanced Banner
clear
echo -e "${PURPLE}"
echo -e "╔══════════════════════════════════════════════════════════════╗"
echo -e "║${CYAN}                                                          ${PURPLE}║"
echo -e "║${CYAN}   ███╗   ██╗ ██████╗ ██████╗ ██╗████████╗ █████╗         ${PURPLE}║"
echo -e "║${CYAN}   ████╗  ██║██╔═══██╗██╔══██╗██║╚══██╔══╝██╔══██╗        ${PURPLE}║"
echo -e "║${CYAN}   ██╔██╗ ██║██║   ██║██████╔╝██║   ██║   ███████║        ${PURPLE}║"
echo -e "║${CYAN}   ██║╚██╗██║██║   ██║██╔══██╗██║   ██║   ██╔══██║        ${PURPLE}║"
echo -e "║${CYAN}   ██║ ╚████║╚██████╔╝██║  ██║██║   ██║   ██║  ██║        ${PURPLE}║"
echo -e "║${CYAN}   ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚═╝  ╚═╝        ${PURPLE}║"
echo -e "║${WHITE}                                                          ${PURPLE}║"
echo -e "║${WHITE}              Nobita Auto Installer                       ${PURPLE}║"
echo -e "║${YELLOW}              (Silent Mode - Minimal Output)               ${PURPLE}║"
echo -e "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# OS Detection
show_progress "Detecting operating system"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
    show_success "Detected: $OS $VER"
else
    show_error "Unsupported OS. Exiting."
    exit 1
fi

sleep 1

# Supported Systems
if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    show_error "Unsupported OS. This script supports Ubuntu/Debian only."
    exit 1
fi

# Domain input with validation
echo -e ""
echo -e "${CYAN}${BOLD}Domain Configuration:${NC}"
echo -e "${WHITE}Please enter your domain name for Jexactyl${NC}"
read -p "$(echo -e "${YELLOW}➤ Enter your domain (example.com): ${NC}")" DOMAIN

if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    show_error "Invalid domain format"
    exit 1
fi

# Generate secure credentials
DB_NAME="Jexpanel"
DB_USER="Jexpaneluser"
DB_PASS=$(openssl rand -base64 32)
JEXACTYL_VERSION="v4.0.0-rc2"

echo -e ""
echo -e "${PURPLE}${BOLD}Starting Jexactyl Installation Process...${NC}"
sleep 2

# Step 1: System Preparation
echo -e "\n${PURPLE}${BOLD}╔════════ Step 1: System Preparation ════════╗${NC}"
run_silent "Updating system packages" "apt-get update -y"
run_silent "Installing dependencies" "apt-get install -y software-properties-common curl apt-transport-https ca-certificates gnupg lsb-release"

# Add PHP repository
show_progress "Adding PHP repository"
if [[ "$OS" == "ubuntu" ]]; then
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
elif [[ "$OS" == "debian" ]]; then
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list > /dev/null
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg > /dev/null 2>&1
fi
show_success "PHP repository added"

run_silent "Updating repository cache" "apt-get update -y"

# Step 2: Package Installation
echo -e "\n${PURPLE}${BOLD}╔════════ Step 2: Package Installation ════════╗${NC}"
show_progress "Installing PHP and services"
animate_text "Installing: PHP 8.3, MariaDB, Nginx, Redis, and extensions..."
apt-get install -y php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server cron &
progress_bar 15
show_success "All packages installed"

show_progress "Installing Composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
show_success "Composer installed"

# Step 3: Jexactyl Setup
echo -e "\n${PURPLE}${BOLD}╔════════ Step 3: Jexactyl Setup ════════╗${NC}"
run_silent "Creating web directory" "mkdir -p /var/www/jexactyl"
cd /var/www/jexactyl || handle_error "Directory change"

show_progress "Downloading Jexactyl files"
curl -Lo panel.tar.gz "https://github.com/jexactyl/jexactyl/releases/download/${JEXACTYL_VERSION}/panel.tar.gz" > /dev/null 2>&1
show_success "Jexactyl downloaded"

run_silent "Extracting files" "tar -xzf panel.tar.gz"
run_silent "Setting permissions" "chmod -R 755 storage/* bootstrap/cache/"
run_silent "Setting ownership" "chown -R www-data:www-data /var/www/jexactyl/*"

# Step 4: Database Setup
echo -e "\n${PURPLE}${BOLD}╔════════ Step 4: Database Setup ════════╗${NC}"
run_silent "Starting MariaDB service" "systemctl enable --now mariadb"

show_progress "Configuring database"
animate_text "Creating database and user with secure credentials..."
mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" > /dev/null 2>&1
mariadb -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};" > /dev/null 2>&1
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;" > /dev/null 2>&1
mariadb -e "FLUSH PRIVILEGES;" > /dev/null 2>&1
show_success "Database '${DB_NAME}' configured with user '${DB_USER}'"

# Step 5: Environment Configuration
echo -e "\n${PURPLE}${BOLD}╔════════ Step 5: Environment Configuration ════════╗${NC}"
run_silent "Copying environment file" "cp -R .env.example .env"

echo "RECAPTCHA_ENABLED=false" >> .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env || handle_error "URL configuration"
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env || handle_error "Database name configuration"
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env || handle_error "Database user configuration"
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env || handle_error "Database password configuration"
show_success "Environment variables configured"

show_progress "Running Composer installation"
animate_text "Installing PHP dependencies - this may take a few minutes..."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader > /dev/null 2>&1
show_success "Composer dependencies installed"

run_silent "Generating application key" "php artisan key:generate --force"
run_silent "Running database migrations" "php artisan migrate --seed --force"

# Step 6: Service Configuration
echo -e "\n${PURPLE}${BOLD}╔════════ Step 6: Service Configuration ════════╗${NC}"
run_silent "Setting up cron service" "systemctl enable --now cron"

show_progress "Configuring scheduled tasks"
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/jexactyl/artisan schedule:run >> /dev/null 2>&1") | crontab - > /dev/null 2>&1
show_success "Cron jobs configured"

# Create queue worker service
show_progress "Setting up queue worker"
cat >/etc/systemd/system/jxctl.service <<EOL
[Unit]
Description=Jexactyl Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/jexactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOL
show_success "Queue worker configured"

run_silent "Enabling queue worker" "systemctl enable --now jxctl.service"

# Step 7: SSL & Web Server
echo -e "\n${PURPLE}${BOLD}╔════════ Step 7: SSL & Web Server ════════╗${NC}"
run_silent "Creating SSL directory" "mkdir -p /etc/certs/Jexpanel"
cd /etc/certs/Jexpanel || handle_error "SSL directory change"

show_progress "Generating SSL certificate"
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" -keyout privkey.pem -out fullchain.pem > /dev/null 2>&1
show_success "SSL certificate generated"

# Create Nginx configuration
show_progress "Configuring Nginx"
cat >/etc/nginx/sites-available/jexactyl.conf <<EOL
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/jexactyl/public;
    index index.php;

    access_log /var/log/nginx/jexactyl-access.log;
    error_log /var/log/nginx/jexactyl-error.log;

    client_max_body_size 100m;
    sendfile off;

    ssl_certificate /etc/certs/Jexpanel/fullchain.pem;
    ssl_certificate_key /etc/certs/Jexpanel/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL
show_success "Nginx configuration created"

run_silent "Enabling site" "ln -sf /etc/nginx/sites-available/jexactyl.conf /etc/nginx/sites-enabled/jexactyl.conf"
run_silent "Testing Nginx configuration" "nginx -t"
run_silent "Restarting web services" "systemctl restart nginx php8.3-fpm"

# Step 8: Final Setup
echo -e "\n${PURPLE}${BOLD}╔════════ Step 8: Final Setup ════════╗${NC}"
cd /var/www/jexactyl || handle_error "Directory change for final setup"

echo -e ""
echo -e "${YELLOW}${BOLD}📝 Admin User Creation${NC}"
echo -e "${CYAN}Please create your admin account when prompted:${NC}"
echo -e "${WHITE}You'll be asked to enter email, username, and name${NC}"
echo -e ""
php artisan p:user:make

run_silent "Finalizing configuration" "sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env && echo 'APP_ENVIRONMENT_ONLY=false' >> .env"

# Service verification
echo -e "\n${PURPLE}${BOLD}╔════════ Service Status Check ════════╗${NC}"
services=("nginx" "php8.3-fpm" "mariadb" "redis-server" "jxctl.service")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo -e "  ${GREEN}✅${NC} $service is running"
    else
        echo -e "  ${RED}❌${NC} $service is NOT running"
    fi
done

# Final check
echo -e "\n${PURPLE}${BOLD}╔════════ Final Verification ════════╗${NC}"
show_progress "Testing web accessibility"
if curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}" | grep -q "200"; then
    show_success "Jexactyl is accessible at https://${DOMAIN}"
else
    show_warning "Jexactyl may take a moment to become available"
    echo -e "${YELLOW}If not accessible immediately, wait 1-2 minutes and refresh${NC}"
fi

# Display final information with enhanced UI
clear
print_header

echo -e "${GREEN}"
animate_text "🎉 Jexactyl Installation Completed Successfully by Nobita!"
echo -e "${NC}"

echo -e ""
echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}${BOLD}║                      📋 INSTALLATION SUMMARY                ║${NC}"
echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e ""

echo -e "${CYAN}${BOLD}🌐 Panel Access:${NC}"
echo -e "  ${WHITE}Panel URL:${NC} ${GREEN}https://${DOMAIN}${NC}"
echo -e ""

echo -e "${CYAN}${BOLD}🗄️  Database Information:${NC}"
echo -e "  ${WHITE}Database:${NC} ${GREEN}${DB_NAME}${NC}"
echo -e "  ${WHITE}DB User:${NC} ${GREEN}${DB_USER}${NC}"
echo -e "  ${WHITE}DB Pass:${NC} ${GREEN}${DB_PASS}${NC}"
echo -e ""

echo -e "${CYAN}${BOLD}📁 File Locations:${NC}"
echo -e "  ${WHITE}Installation:${NC} ${GREEN}/var/www/jexactyl${NC}"
echo -e "  ${WHITE}SSL Certificates:${NC} ${GREEN}/etc/certs/Jexpanel${NC}"
echo -e "  ${WHITE}Log File:${NC} ${GREEN}${log_file}${NC}"
echo -e ""

echo -e "${YELLOW}${BOLD}⚠️  Important Notes:${NC}"
echo -e "  ${WHITE}• Change the default database password for production${NC}"
echo -e "  ${WHITE}• Replace self-signed SSL with valid certificate${NC}"
echo -e "  ${WHITE}• Configure your DNS to point to this server${NC}"
echo -e ""

echo -e "${CYAN}${BOLD}🔧 Management Commands:${NC}"
echo -e "  ${WHITE}Create users:${NC} cd /var/www/jexactyl && php artisan p:user:make"
echo -e "  ${WHITE}View logs:${NC} tail -f ${log_file}"
echo -e ""

echo -e "${GREEN}${BOLD}✅ Your Jexactyl panel is ready to use!${NC}"
echo -e "${PURPLE}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}${BOLD}║                    🚀 Happy Hosting!                        ║${NC}"
echo -e "${PURPLE}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
