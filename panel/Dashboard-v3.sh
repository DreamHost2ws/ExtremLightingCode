#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_status() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

print_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Global variable for domain
DOMAIN=""

# Function to get domain from user
get_domain() {
    echo ""
    echo -e "${GREEN}=== Domain Setup ===${NC}"
    echo -e "${YELLOW}Please enter your domain name for MythicalDash panel${NC}"
    echo -e "${YELLOW}Example: panel.yourdomain.com or dash.example.com${NC}"
    echo ""
    read -p "Enter your domain: " DOMAIN
    
    # Basic domain validation
    if [[ -z "$DOMAIN" ]]; then
        print_error "Domain cannot be empty!"
        exit 1
    fi
    
    # Remove http:// or https:// and trailing slashes if present
    DOMAIN=$(echo "$DOMAIN" | sed -E 's|^https?://||' | sed 's|/$||')
    
    # Remove www. if present
    DOMAIN=$(echo "$DOMAIN" | sed 's|^www\.||')
    
    echo ""
    print_success "Domain set to: $DOMAIN"
    echo ""
    
    # Confirm domain
    read -p "Is this domain correct? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Domain confirmation failed. Please run the script again."
        exit 0
    fi
}

# Function to detect if Ubuntu/Debian
check_ubuntu_debian() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
            echo -e "${GREEN}Detected OS: $PRETTY_NAME ${NC}"
            return 0
        else
            print_error "This script only works on Ubuntu/Debian systems"
            echo -e "${YELLOW}Detected OS: $PRETTY_NAME ${NC}"
            exit 1
        fi
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
}

# Function to setup Nginx configuration
setup_nginx() {
    print_status "Setting up Nginx configuration for $DOMAIN..."
    
    # Create logs directory
    mkdir -p /var/www/mythicaldash/logs
    
    # Create Nginx configuration file
    cat > /etc/nginx/sites-available/MythicalDash.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    root /var/www/mythicaldash/public;
    index index.php;

    access_log /var/www/mythicaldash/logs/mythicaldash.app-access.log;
    error_log  /var/www/mythicaldash/logs/mythicaldash.app-error.log error;

    # allow larger file uploads and longer script runtimes
    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration - Using self-signed certificate for now
    ssl_certificate /etc/certs/MythicalDash/fullchain.pem;
    ssl_certificate_key /etc/certs/MythicalDash/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    # See https://hstspreload.org/ before uncommenting the line below.
    # add_header Strict-Transport-Security "max-age=15768000; preload;";
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Enable the site
    if [ -f /etc/nginx/sites-enabled/default ]; then
        rm /etc/nginx/sites-enabled/default
    fi
    
    ln -sf /etc/nginx/sites-available/MythicalDash.conf /etc/nginx/sites-enabled/
    
    # Test Nginx configuration
    print_status "Testing Nginx configuration..."
    nginx -t
    
    if [ $? -eq 0 ]; then
        print_success "Nginx configuration test passed"
        
        # Restart Nginx
        print_status "Restarting Nginx service..."
        systemctl restart nginx
        systemctl enable nginx
        
        if systemctl is-active --quiet nginx; then
            print_success "Nginx service restarted successfully"
        else
            print_error "Failed to restart Nginx"
            exit 1
        fi
    else
        print_error "Nginx configuration test failed"
        exit 1
    fi
}

# Function to setup MariaDB database
setup_database() {
    print_status "Setting up MariaDB database..."
    
    DB_NAME=mythicaldash
    DB_USER=mythicaldash
    DB_PASS=1234

    # Start MariaDB if not running
    print_status "Starting MariaDB service..."
    systemctl start mariadb 2>/dev/null || systemctl start mysql 2>/dev/null
    systemctl enable mariadb 2>/dev/null || systemctl enable mysql 2>/dev/null
    
    # Check if MySQL/MariaDB is running
    if ! systemctl is-active --quiet mariadb && ! systemctl is-active --quiet mysql; then
        print_error "Failed to start MariaDB/MySQL service"
        exit 1
    fi

    # Create database and user
    print_status "Creating database and user..."
    mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null
    mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};" 2>/dev/null
    mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;" 2>/dev/null
    mysql -e "FLUSH PRIVILEGES;" 2>/dev/null
    
    # Verify creation
    if mysql -e "USE ${DB_NAME};" 2>/dev/null; then
        print_success "Database '${DB_NAME}' created with user '${DB_USER}'"
    else
        print_error "Failed to create database or user"
        exit 1
    fi
}

# Function to setup MythicalDash
setup_mythicaldash() {
    print_status "Running MythicalDash setup commands..."
    
    cd /var/www/mythicaldash
    
    # Run arch.bash
    print_status "Running architecture check..."
    dos2unix arch.bash
    bash arch.bash
    
    # Set executable permission and run setup commands
    chmod +x ./MythicalDash
    
    print_status "Generating new configuration..."
    ./MythicalDash -environment:newconfig
    
    print_status "Generating encryption key..."
    ./MythicalDash -key:generate
    
    print_status "Setting up database connection..."
    ./MythicalDash -environment:database
    
    print_status "Running database migrations..."
    ./MythicalDash -migrate
    
    print_status "Starting custom setup..."
    ./MythicalDash -environment:setup
    
    print_success "MythicalDash setup completed"
}

# Function to setup SSL certificates
setup_ssl_certificates() {
    print_status "Setting up SSL certificates..."
    
    mkdir -p /etc/certs/MythicalDash
    cd /etc/certs/MythicalDash
    
    # Generate self-signed SSL certificate
    print_status "Generating self-signed SSL certificate..."
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
        -subj "/C=NA/ST=NA/L=NA/O=NA/CN=$DOMAIN" \
        -keyout privkey.pem -out fullchain.pem
    
    if [ -f "privkey.pem" ] && [ -f "fullchain.pem" ]; then
        print_success "SSL certificates generated successfully for $DOMAIN"
        print_status "Certificate location: /etc/certs/MythicalDash/"
    else
        print_error "Failed to generate SSL certificates"
        exit 1
    fi
}

# Function to setup cron jobs
setup_cron_jobs() {
    print_status "Setting up cron jobs..."
    
    # Install cron if not installed
    apt install -y cron
    systemctl enable --now cron
    
    # Add cron job for server.php
    (crontab -l 2>/dev/null; echo "* * * * * php /var/www/mythicaldash/crons/server.php >> /dev/null 2>&1") | crontab -
    
    # Verify cron job was added
    if crontab -l | grep -q "server.php"; then
        print_success "Cron job for server.php added successfully"
    else
        print_error "Failed to add cron job"
        exit 1
    fi
}

# Function to setup Ubuntu/Debian
setup_ubuntu_debian() {
    echo -e "${YELLOW}Starting Ubuntu/Debian setup...${NC}"
    
    # Step 1: Update the server
    print_status "Step 1: Updating system packages..."
    apt update && apt upgrade -y
    if [ $? -eq 0 ]; then
        print_success "System updated successfully"
    else
        print_error "Failed to update system"
        exit 1
    fi
    
    # Step 2: Add "add-apt-repository" command
    print_status "Step 2: Installing required packages..."
    apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
    if [ $? -eq 0 ]; then
        print_success "Required packages installed"
    else
        print_error "Failed to install required packages"
        exit 1
    fi
    
    # Step 3: Add PHP repository
    print_status "Step 3: Adding PHP repository..."
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    if [ $? -eq 0 ]; then
        print_success "PHP repository added"
    else
        print_error "Failed to add PHP repository"
        exit 1
    fi
    
    # Step 4: Update repositories list
    print_status "Step 4: Updating repositories..."
    apt update
    if [ $? -eq 0 ]; then
        print_success "Repositories updated"
    else
        print_error "Failed to update repositories"
        exit 1
    fi
    
    # Step 5: Add universe repository
    print_status "Step 5: Adding universe repository..."
    add-apt-repository universe
    if [ $? -eq 0 ]; then
        print_success "Universe repository added"
    else
        print_error "Failed to add universe repository"
        exit 1
    fi
    
    # Step 6: Install Dependencies
    print_status "Step 6: Installing PHP and other dependencies..."
    apt -y install php8.2 php8.2-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip zip git redis-server dos2unix
    
    if [ $? -eq 0 ]; then
        print_success "All dependencies installed successfully"
    else
        print_error "Some dependencies failed to install"
        exit 1
    fi
    
    # Step 7: Install Composer
    print_status "Step 7: Installing Composer..."
    curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer
    if [ $? -eq 0 ]; then
        print_success "Composer installed successfully"
        composer --version
    else
        print_error "Failed to install Composer"
        exit 1
    fi
    
    # Step 8: Create MythicalDash directory
    print_status "Step 8: Setting up MythicalDash..."
    mkdir -p /var/www/mythicaldash
    if [ $? -eq 0 ]; then
        print_success "Directory created: /var/www/mythicaldash"
    else
        print_error "Failed to create directory"
        exit 1
    fi
    
    # Step 9: Download and extract MythicalDash
    print_status "Step 9: Downloading MythicalDash..."
    cd /var/www/mythicaldash
    curl -Lo MythicalDash.zip https://github.com/MythicalLTD/MythicalDash/releases/download/3.2.3/MythicalDash.zip
    if [ $? -eq 0 ]; then
        print_success "MythicalDash downloaded successfully"
    else
        print_error "Failed to download MythicalDash"
        exit 1
    fi
    
    print_status "Extracting MythicalDash..."
    unzip -o MythicalDash.zip -d /var/www/mythicaldash
    if [ $? -eq 0 ]; then
        print_success "MythicalDash extracted successfully"
    else
        print_error "Failed to extract MythicalDash"
        exit 1
    fi
    
    # Step 10: Set proper permissions
    print_status "Step 10: Setting permissions..."
    chown -R www-data:www-data /var/www/mythicaldash/*
    if [ $? -eq 0 ]; then
        print_success "Permissions set successfully"
    else
        print_error "Failed to set permissions"
        exit 1
    fi
    
    # Step 11: Install Composer dependencies
    print_status "Step 11: Installing Composer dependencies..."
    cd /var/www/mythicaldash
    composer install --no-dev --optimize-autoloader
    if [ $? -eq 0 ]; then
        print_success "Composer dependencies installed successfully"
    else
        print_error "Failed to install Composer dependencies"
        exit 1
    fi
    
    # Step 12: Setup SSL certificates
    setup_ssl_certificates
    
    # Step 13: Setup MariaDB database
    setup_database
    
    # Step 14: Run MythicalDash setup
    setup_mythicaldash
    
    # Step 15: Setup Nginx configuration
    setup_nginx
    
    # Step 16: Setup cron jobs
    setup_cron_jobs
    
    # Step 17: Show installed versions and final info
    print_status "Step 17: Verifying installations..."
    echo -e "${YELLOW}PHP Version:${NC}"
    php -v | head -n 1
    echo -e "${YELLOW}MySQL Version:${NC}"
    mysql --version
    echo -e "${YELLOW}Nginx Version:${NC}"
    nginx -v
    echo -e "${YELLOW}Redis Version:${NC}"
    redis-server --version
    echo -e "${YELLOW}Composer Version:${NC}"
    composer --version
    
    print_success "========================================"
    print_success "Ubuntu/Debian setup completed successfully!"
    print_success "========================================"
    echo -e "${YELLOW}Setup Summary:${NC}"
    echo -e "• Domain: $DOMAIN"
    echo -e "• Panel URL: https://$DOMAIN"
    echo -e "• Database: mythicaldash (user: mythicaldash)"
    echo -e "• SSL: Self-signed certificate generated"
    echo -e ""
    echo -e "${YELLOW}Important files and directories:${NC}"
    echo -e "• MythicalDash: /var/www/mythicaldash/"
    echo -e "• SSL Certificates: /etc/certs/MythicalDash/"
    echo -e "• Nginx Config: /etc/nginx/sites-available/MythicalDash.conf"
    echo -e "• Logs: /var/www/mythicaldash/logs/"
    echo -e ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo -e "1. Configure MySQL security: mysql_secure_installation"
    echo -e "2. Update DNS records to point $DOMAIN to your server IP"
    echo -e "3. For production, replace self-signed SSL with Let's Encrypt"
    echo -e "4. Configure firewall if needed"
    echo -e "5. Access your panel at: https://$DOMAIN"
    echo -e ""
    echo -e "${RED}Note: Browser will show SSL warning for self-signed certificate${NC}"
    echo -e "${RED}For production, use Let's Encrypt for trusted SSL certificate${NC}"
}

# Main script execution
main() {
    echo -e "${GREEN}=== MythicalDash Auto Setup Script ===${NC}"
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "Please run as root (use sudo)"
        exit 1
    fi
    
    # Check if Ubuntu/Debian
    check_ubuntu_debian
    
    # Get domain from user FIRST
    get_domain
    
    # Confirm before proceeding with installation
    echo ""
    echo -e "${YELLOW}This script will install:${NC}"
    echo -e "• PHP 8.2, MariaDB, Nginx, Redis"
    echo -e "• Composer and dependencies"
    echo -e "• MythicalDash panel for domain: $DOMAIN"
    echo -e "• SSL Certificate (self-signed)"
    echo -e "• Database and cron jobs"
    echo ""
    read -p "Do you want to continue with installation? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        exit 0
    fi
    
    # Start setup
    setup_ubuntu_debian
}

# Run main function
main
