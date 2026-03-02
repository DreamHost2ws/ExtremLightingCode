#!/bin/bash

# =============================================
#  HyperV1 Theme Installer / Upgrader
#  Compatible: Ubuntu, Debian, Fedora, CentOS, Arch, etc.
# =============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
USE_LOCAL_FILES=0

for _arg in "$@"; do
    case "$_arg" in
        --local) USE_LOCAL_FILES=1 ;;
    esac
done
unset _arg

if [[ "$EUID" -ne 0 ]]; then
    echo "Error: This script must be run as root or with sudo privileges."
    exit 1
fi

read -rp "Enter your Pterodactyl panel path [/var/www/pterodactyl]: " PANEL_PATH
PANEL_PATH=${PANEL_PATH:-/var/www/pterodactyl}

if [[ ! -d "$PANEL_PATH" ]]; then
    echo "Error: Path $PANEL_PATH does not exist!"
    exit 1
fi

echo ""
echo "=============================="
echo "   HyperV1 Theme Installer"
echo "=============================="
echo "1) Install HyperV1 Theme"
echo "2) Upgrade HyperV1 Theme"
echo "3) Restore from Backup"
echo "=============================="
read -rp "Choose an option (1, 2, or 3): " OPTION

backup_panel() {
    echo "Backing up your panel files (excluding vendor/, logs, cache)..."
    cd /var/www || exit
    tar -czf "pterodactyl_backup_$(date +%Y%m%d_%H%M%S).tar.gz" \
        --exclude='pterodactyl/vendor' \
        --exclude='pterodactyl/node_modules' \
        --exclude='pterodactyl/storage/logs' \
        --exclude='pterodactyl/storage/framework/cache' \
        pterodactyl/
    local tar_exit=$?
    if [ $tar_exit -eq 2 ]; then
        echo "Backup failed (fatal tar error)."
        exit 1
    fi
    echo "Backup completed."
}

backup_hyperv1() {
    echo "Backing up HyperV1 theme and settings..."
    cd "$PANEL_PATH" || exit
    
    local dump_script="$PANEL_PATH/dump_hyper_settings.php"
    cat << 'EOF' > "$dump_script"
$settings = DB::table('settings')->where('key', 'like', '%theme%')->orWhere('key', 'like', '%hyper%')->get();
$sql = "/* HyperV1 Settings Backup */\n";
foreach ($settings as $setting) {
    $key = addslashes($setting->key);
    $value = addslashes($setting->value);
    $sql .= "INSERT INTO `settings` (`key`, `value`) VALUES ('$key', '$value') ON DUPLICATE KEY UPDATE `value`=VALUES(`value`);\n";
}
file_put_contents('/var/www/pterodactyl/hyperv1_settings_backup.sql', $sql);
EOF
    
    echo "Exporting settings using Artisan..."
    php artisan tinker < "$dump_script" >/dev/null 2>&1 || true
    rm -f "$dump_script"
    
    local backup_name="hyperv1_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    echo "Creating theme archive: $backup_name"
    cd /var/www || exit
    tar -czf "$backup_name" pterodactyl/rolexdev/ pterodactyl/public/rolexdev/ pterodactyl/public/assets/hyper* pterodactyl/hyperv1_settings_backup.sql 2>/dev/null || true
    rm -f pterodactyl/hyperv1_settings_backup.sql
    echo "HyperV1 Backup completed: /var/www/$backup_name"
}


manage_backups() {

    mapfile -t BACKUPS < <(find /var/www -type f -name "pterodactyl_backup_*.tar.gz" -print | sort -r)
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        return
    fi
    echo "Existing backups (newest first):"
    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1))) ${BACKUPS[$i]}"
    done
    MOST_RECENT="${BACKUPS[0]}"
    echo "The most recent backup is $MOST_RECENT"
    read -rp "Do you want to delete some old backups? (y/N): " DELETE_OLD
    if [[ "$DELETE_OLD" =~ ^[Yy]$ ]]; then
        echo "Enter the numbers of backups to delete (space separated): "
        read -r TO_DELETE
        for num in $TO_DELETE; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#BACKUPS[@]} ]; then
                SELECTED="${BACKUPS[$((num-1))]}"
                if [ "$SELECTED" = "$MOST_RECENT" ]; then
                    read -rp "Are you sure you want to delete the most recent backup $SELECTED? (y/N): " CONFIRM_DELETE_RECENT
                    if [[ "$CONFIRM_DELETE_RECENT" =~ ^[Yy]$ ]]; then
                        rm "$SELECTED"
                        echo "Deleted $SELECTED"
                    fi
                else
                    rm "$SELECTED"
                    echo "Deleted $SELECTED"
                fi
            fi
        done
    fi
}

remove_old_assets() {
    echo "Removing old build files..."
    find "$PANEL_PATH/public/assets" -type f \( -name "*.js" -o -name "*.json" -o -name "*.js.map" \) -delete
}

install_hyperv1_files() {
    echo "Downloading and extracting HyperV1 theme..."
    cd "$PANEL_PATH" || exit
    TAR_FILE="Hyperv1.tar"
    DOWNLOAD_URL="https://r2.rolexdev.tech/hyperv1/Hyperv1.tar"
    rm -f "$TAR_FILE" || true

    if [[ "$USE_LOCAL_FILES" == "1" ]]; then
        if [[ -f "${SCRIPT_DIR}/Hyperv1.tar" ]]; then
            echo "[--local] Using local Hyperv1.tar from ${SCRIPT_DIR}."
            cp "${SCRIPT_DIR}/Hyperv1.tar" "$TAR_FILE"
        else
            echo "Error: --local specified but Hyperv1.tar not found in ${SCRIPT_DIR}" >&2
            exit 1
        fi
    elif command -v curl >/dev/null 2>&1; then
        echo "Attempting download with curl..."
        if curl -f --retry 3 --retry-delay 2 --progress-bar -o "$TAR_FILE" "$DOWNLOAD_URL"; then
            echo "Downloaded Hyperv1.tar with curl"
        else
            echo "curl failed, attempting wget..."
            if command -v wget >/dev/null 2>&1 && wget --show-progress -O "$TAR_FILE" "$DOWNLOAD_URL"; then
                echo "Downloaded Hyperv1.tar with wget"
            else
                echo "Error: failed to download Hyperv1.tar with curl and wget"
                rm -f "$TAR_FILE" || true
                exit 1
            fi
        fi
    elif command -v wget >/dev/null 2>&1; then
        echo "curl not found; downloading with wget..."
        if wget --show-progress -O "$TAR_FILE" "$DOWNLOAD_URL"; then
            echo "Downloaded Hyperv1.tar with wget"
        else
            echo "Error: wget failed to download Hyperv1.tar"
            rm -f "$TAR_FILE" || true
            exit 1
        fi
    else
        echo "Error: neither curl nor wget is available to download Hyperv1.tar"
        exit 1
    fi

    echo "Removing app/ directory before extraction..."
    rm -rf "$PANEL_PATH/app"
    echo "Extracting $TAR_FILE..."
    tar -xf "$TAR_FILE" --overwrite
}

set_permissions() {
    echo "Setting correct permissions..."
    chown -R www-data:www-data "$PANEL_PATH"/*
    chmod -R 755 "$PANEL_PATH"/storage/* "$PANEL_PATH"/bootstrap/cache/
    
    if [[ -f "$PANEL_PATH/storage/app/discord_bot_heartbeat" ]]; then
        chown www-data:www-data "$PANEL_PATH/storage/app/discord_bot_heartbeat"
        echo "Fixed permissions for discord_bot_heartbeat"
    fi
}

set_fetch_permissions() {
    echo "Setting executable permissions for hyper_fetch and hyper_auto_update_ioncube (if present)..."

    if [[ -z "${PANEL_PATH:-}" ]]; then
        echo "PANEL_PATH not set; skipping fetch permission step."
        return
    fi

    FETCH_FILE="$PANEL_PATH/hyper_fetch.sh"
    AUTO_UPDATE_FILE="$PANEL_PATH/hyper_auto_update_ioncube.sh"

    if [[ -f "$FETCH_FILE" ]]; then
        chmod +x "$FETCH_FILE" || true
        chown www-data:www-data "$FETCH_FILE" || true
        echo "Set executable on $FETCH_FILE"
    else
        echo "Warning: $FETCH_FILE not found; it may be extracted later."
    fi

    if [[ -f "$AUTO_UPDATE_FILE" ]]; then
        chmod +x "$AUTO_UPDATE_FILE" || true
        chown www-data:www-data "$AUTO_UPDATE_FILE" || true
        echo "Set executable on $AUTO_UPDATE_FILE"
    fi
    if [[ -f "$PANEL_PATH/hyper_auto_update.sh" ]]; then
        chmod +x "$PANEL_PATH/hyper_auto_update.sh" || true
        chown www-data:www-data "$PANEL_PATH/hyper_auto_update.sh" || true
    fi

    SUDOERS_FILE="/etc/sudoers.d/hyper_update"
    echo "Creating sudoers entry at $SUDOERS_FILE"
    printf 'www-data ALL=(ALL) NOPASSWD: %s/hyper_fetch.sh, %s/hyper_auto_update.sh, %s/hyper_auto_update_ioncube.sh\n' "$PANEL_PATH" "$PANEL_PATH" "$PANEL_PATH" > "$SUDOERS_FILE"
    chmod 0440 "$SUDOERS_FILE" || true

    if command -v visudo >/dev/null 2>&1; then
        if visudo -cf "$SUDOERS_FILE" >/dev/null 2>&1; then
            echo "Sudoers file $SUDOERS_FILE validated"
        else
            echo "Warning: sudoers validation failed for $SUDOERS_FILE"
        fi
    else
        echo "Note: visudo not found; skipping sudoers syntax validation"
    fi
}

fix_cron() {
    echo "Setting up Laravel scheduler via Supervisor (schedule:work)..."

    for user in root www-data nginx apache; do
        if id "$user" &>/dev/null || [ "$user" = "root" ]; then
            local ctab
            if [ "$user" = "root" ]; then
                ctab=$(crontab -l 2>/dev/null) || true
            else
                ctab=$(crontab -u "$user" -l 2>/dev/null) || true
            fi
            if echo "$ctab" | grep -Fq "php /var/www/pterodactyl/artisan schedule:run"; then
                echo "Removing schedule:run from $user crontab..."
                if [ "$user" = "root" ]; then
                    (crontab -l 2>/dev/null | grep -Fv "php /var/www/pterodactyl/artisan schedule:run") | crontab -
                else
                    (crontab -u "$user" -l 2>/dev/null | grep -Fv "php /var/www/pterodactyl/artisan schedule:run") | crontab -u "$user" -
                fi
            fi
        fi
    done

    if grep -rFq "php /var/www/pterodactyl/artisan schedule:run" /etc/cron.d/ 2>/dev/null; then
        echo "Removing schedule:run from /etc/cron.d/..."
        grep -rlF "php /var/www/pterodactyl/artisan schedule:run" /etc/cron.d/ | xargs sed -i '/php \/var\/www\/pterodactyl\/artisan schedule:run/d'
    fi

    if ! command -v supervisord &>/dev/null; then
        echo "Supervisor not found. Installing..."
        apt-get install -y supervisor &>/dev/null || { echo "Failed to install supervisor"; return 1; }
        systemctl enable supervisor &>/dev/null
        systemctl start supervisor &>/dev/null
    fi

    chown -R www-data:www-data /var/www/pterodactyl/storage 2>/dev/null

    mkdir -p /var/log/pterodactyl
    chown www-data:www-data /var/log/pterodactyl

    local CONF="/etc/supervisor/conf.d/pterodactyl-scheduler.conf"

    if supervisorctl status pterodactyl-scheduler 2>/dev/null | grep -q "RUNNING"; then
        echo "pterodactyl-scheduler is already running via Supervisor. Skipping setup."
        return 0
    fi

    echo "Creating Supervisor config for pterodactyl-scheduler..."
    cat > "$CONF" <<'EOF'
[program:pterodactyl-scheduler]
command=php /var/www/pterodactyl/artisan schedule:work
user=www-data
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/pterodactyl/scheduler.err.log
stdout_logfile=/dev/null
EOF

    supervisorctl reread &>/dev/null
    supervisorctl update &>/dev/null

    if supervisorctl status pterodactyl-scheduler 2>/dev/null | grep -q "RUNNING"; then
        echo "pterodactyl-scheduler started successfully via Supervisor."
    else
        supervisorctl start pterodactyl-scheduler &>/dev/null
        echo "pterodactyl-scheduler started."
    fi
}

configure_reverse_proxy_permissions() {
    echo "Configuring permissions for Reverse Proxy addon..."

    if id "www-data" &>/dev/null; then
        WEB_USER="www-data"
    elif id "nginx" &>/dev/null; then
        WEB_USER="nginx"
    elif id "apache" &>/dev/null; then
        WEB_USER="apache"
    else
        echo "Warning: Could not detect web user (www-data, nginx, or apache). Skipping sudoers configuration."
        return
    fi
    echo "Detected web user: $WEB_USER"

    if ! command -v nginx &>/dev/null; then
        echo "Warning: NGINX is not installed. Reverse Proxy addon requires NGINX."
    fi
    if ! command -v certbot &>/dev/null; then
        echo "Warning: Certbot is not installed. SSL generation will not work."
    fi

    SUDOERS_FILE="/etc/sudoers.d/pterodactyl-reverse-proxy"
    BACKUP_FILE="${SUDOERS_FILE}.bak.$(date +%Y%m%d_%H%M%S)"
    WRAPPER_DEST="/usr/local/bin/ptero-reverse-proxy-helper"

    LEGACY_WRAPPERS=("/usr/bin/ptero-reverse-proxy-helper" "/usr/local/sbin/ptero-reverse-proxy-helper" "/usr/local/bin/ptero-reverse-proxy-helper")
    for lw in "${LEGACY_WRAPPERS[@]}"; do
        if [[ -f "$lw" ]]; then
            echo "Removing legacy wrapper $lw"
            rm -f "$lw" || true
        fi
    done

    if [[ -f "$SUDOERS_FILE" ]]; then
        echo "Backing up and removing existing sudoers file $SUDOERS_FILE to $BACKUP_FILE"
        cp -a "$SUDOERS_FILE" "$BACKUP_FILE" || true
        rm -f "$SUDOERS_FILE" || true
    fi

    echo "Creating robust wrapper at $WRAPPER_DEST"
    cat > "$WRAPPER_DEST" <<'WRAPPER'
#!/usr/bin/env bash
set -euo pipefail

allowed_site_dir="/etc/nginx/sites-enabled"
allowed_ssl_dir="/etc/nginx/ssl"

realpath_safe() {
    command -v realpath >/dev/null 2>&1 || { echo "realpath required" >&2; exit 1; }
    realpath -m "$1"
}

is_under_dir() {
    local path; local dir
    path=$(realpath_safe "$1")
    dir=$(realpath_safe "$2")
    case "$path" in
        "$dir"|"$dir"/*) return 0 ;;
        *) return 1 ;;
    esac
}

ensure_domain_filename() {
    local filename="$1"
    if [[ ! $filename =~ ^[a-zA-Z0-9._-]+(\.conf|\.crt|\.key)$ ]]; then
        echo "Filename must be <domain>.conf|.crt|.key; got $filename" >&2
        exit 1
    fi
}

ensure_source_in_tmp() {
    local src="$1"
    if [[ ! $src =~ ^/tmp/ ]]; then
        echo "Source must be under /tmp/" >&2
        exit 1
    fi
    if [[ ! -f "$src" ]]; then
        echo "Source file not found: $src" >&2
        exit 1
    fi
}

case "$1" in
    mv)
        if [[ $# -ne 3 ]]; then echo "Usage: $0 mv <src> <dest>" >&2; exit 1; fi
        ensure_source_in_tmp "$2"
        dest_real=$(realpath_safe "$3")
        if is_under_dir "$dest_real" "$allowed_site_dir"; then
            ensure_domain_filename "$(basename "$dest_real")"
            mv -- "$2" "$dest_real"
            chown root:root "$dest_real"
            chmod 644 "$dest_real"
        elif is_under_dir "$dest_real" "$allowed_ssl_dir"; then
            ensure_domain_filename "$(basename "$dest_real")"
            mv -- "$2" "$dest_real"
            chown root:root "$dest_real"
            if [[ "$dest_real" =~ \.key$ ]]; then
                chmod 600 "$dest_real"
            else
                chmod 644 "$dest_real"
            fi
        else
            echo "Destination not allowed: $dest_real" >&2
            exit 1
        fi
        ;;
    rm)
        if [[ $# -ne 2 ]]; then echo "Usage: $0 rm <path>" >&2; exit 1; fi
        target=$(realpath_safe "$2")
        if is_under_dir "$target" "$allowed_site_dir" || is_under_dir "$target" "$allowed_ssl_dir"; then
            rm -f -- "$target"
        else
            echo "Can only remove files under $allowed_site_dir or $allowed_ssl_dir" >&2
            exit 1
        fi
        ;;
    chown-root)
        if [[ $# -ne 2 ]]; then echo "Usage: $0 chown-root <path>" >&2; exit 1; fi
        target=$(realpath_safe "$2")
        if is_under_dir "$target" "$allowed_site_dir" || is_under_dir "$target" "$allowed_ssl_dir"; then
            chown root:root "$target"
        else
            echo "Can only chown files under $allowed_site_dir or $allowed_ssl_dir" >&2
            exit 1
        fi
        ;;
    chmod)
        if [[ $# -ne 3 ]]; then echo "Usage: $0 chmod <mode> <path>" >&2; exit 1; fi
        mode="$2"; target=$(realpath_safe "$3")
        if [[ "$mode" != "644" && "$mode" != "600" ]]; then echo "Only modes 644 and 600 are allowed" >&2; exit 1; fi
        if is_under_dir "$target" "$allowed_site_dir" || is_under_dir "$target" "$allowed_ssl_dir"; then
            chmod "$mode" "$target"
        else
            echo "Can only chmod files under $allowed_site_dir or $allowed_ssl_dir" >&2
            exit 1
        fi
        ;;
    mkdir)
        if [[ $# -ne 3 || "$2" != "-p" ]]; then echo "Usage: $0 mkdir -p <path>" >&2; exit 1; fi
        path=$(realpath_safe "$3")
        if [[ "$path" != "$allowed_ssl_dir" ]]; then echo "Only mkdir -p $allowed_ssl_dir allowed" >&2; exit 1; fi
        mkdir -p "$path"
        chown root:root "$path"
        ;;
    nginx-test)
        nginx -t
        ;;
    nginx-reload)
        service nginx reload
        ;;
    certbot-issue)
        if [[ $# -ne 3 ]]; then echo "Usage: $0 certbot-issue <domain> <email>" >&2; exit 1; fi
        certbot --nginx -d "$2" --non-interactive --agree-tos --email "$3" --redirect
        ;;
    certbot-delete)
        if [[ $# -ne 2 ]]; then echo "Usage: $0 certbot-delete <domain>" >&2; exit 1; fi
        certbot delete --cert-name "$2" --non-interactive
        ;;
    *)
        echo "Unknown command" >&2; exit 1
        ;;
esac
WRAPPER
    chown root:root "$WRAPPER_DEST" || true
    chmod 0750 "$WRAPPER_DEST" || true

    echo "Creating minimal sudoers file allowing only the wrapper script"
    cat <<EOF > "$SUDOERS_FILE"
$WEB_USER ALL=(ALL) NOPASSWD: /usr/local/bin/ptero-reverse-proxy-helper
EOF

    chmod 0440 "$SUDOERS_FILE" || true

    if command -v visudo >/dev/null 2>&1; then
        if visudo -cf "$SUDOERS_FILE" >/dev/null 2>&1; then
            echo "Sudoers file $SUDOERS_FILE validated"
        else
            echo "Warning: sudoers validation failed for $SUDOERS_FILE; restoring backup"
            cp -a "$BACKUP_FILE" "$SUDOERS_FILE" || true
        fi
    fi

    mkdir -p /etc/nginx/sites-enabled
    mkdir -p /etc/nginx/ssl
    echo "Ensured /etc/nginx/sites-enabled and /etc/nginx/ssl exist."

    OLD_SUDOERS="/etc/sudoers.d/pterodactyl-reverse-proxy-old"
    if [[ -f "$OLD_SUDOERS" ]]; then
        echo "Removing legacy sudoers fragment: $OLD_SUDOERS"
        rm -f "$OLD_SUDOERS" || true
    fi

    LEGACY_WRAPPERS=("/usr/bin/ptero-reverse-proxy-helper" "/usr/local/sbin/ptero-reverse-proxy-helper")
    for lw in "${LEGACY_WRAPPERS[@]}"; do
        if [[ -f "$lw" && ! -f "$WRAPPER_DEST" ]]; then
            echo "Removing legacy wrapper $lw"
            rm -f "$lw" || true
        fi
    done
}

clear_cache() {
    echo "Clearing Laravel cache..."
    cd "$PANEL_PATH" || exit
    php artisan config:clear
    php artisan cache:clear
    php artisan route:clear
    php artisan view:clear
    php artisan optimize
    php artisan queue:restart
}

migrate_db() {
    echo "Migrating database..."
    cd "$PANEL_PATH" || exit
    php artisan migrate --force

    echo "Configuring seeders to only seed specific Hyper Eggs & Nests..."
    cp database/Seeders/NestSeeder.php database/Seeders/NestSeeder.php.bak 2>/dev/null || true
    cp database/Seeders/EggSeeder.php database/Seeders/EggSeeder.php.bak 2>/dev/null || true

    if [[ -f database/Seeders/NestSeeder.php ]]; then
        sed -i 's/$this->createMinecraftNest/\/\/$this->createMinecraftNest/g' database/Seeders/NestSeeder.php
        sed -i 's/$this->createSourceEngineNest/\/\/$this->createSourceEngineNest/g' database/Seeders/NestSeeder.php
        sed -i 's/$this->createVoiceServersNest/\/\/$this->createVoiceServersNest/g' database/Seeders/NestSeeder.php
        sed -i 's/$this->createRustNest/\/\/$this->createRustNest/g' database/Seeders/NestSeeder.php
    fi

    if [[ -f database/Seeders/EggSeeder.php ]]; then
        sed -i "/'Minecraft',/d" database/Seeders/EggSeeder.php
        sed -i "/'Source Engine',/d" database/Seeders/EggSeeder.php
        sed -i "/'Voice Servers',/d" database/Seeders/EggSeeder.php
        sed -i "/'Rust',/d" database/Seeders/EggSeeder.php
    fi

    php artisan db:seed --class=NestSeeder --force --no-interaction || echo "NestSeeder skipped (non-fatal, data may already exist)"
    php artisan db:seed --class=EggSeeder --force --no-interaction || echo "EggSeeder skipped (non-fatal, data may already exist)"

    mv database/Seeders/NestSeeder.php.bak database/Seeders/NestSeeder.php 2>/dev/null || true
    mv database/Seeders/EggSeeder.php.bak database/Seeders/EggSeeder.php 2>/dev/null || true
}

install_dependencies() {
    echo "Installing dependencies..."
    cd "$PANEL_PATH" || exit

    export COMPOSER_ALLOW_SUPERUSER=1

    composer show intervention/image >/dev/null 2>&1 || { echo "Requiring intervention/image..."; composer require intervention/image --no-interaction; }

    composer show laragear/webauthn >/dev/null 2>&1 || { echo "Requiring laragear/webauthn..."; composer require laragear/webauthn --no-interaction; }

    composer show laravel/socialite >/dev/null 2>&1 || { echo "Requiring laravel/socialite..."; composer require laravel/socialite --no-interaction; }

    composer show socialiteproviders/whmcs >/dev/null 2>&1 || { echo "Requiring socialiteproviders/whmcs..."; composer require socialiteproviders/whmcs --no-interaction; }

    composer install --no-dev --optimize-autoloader --no-interaction

    composer show team-reflex/discord-php >/dev/null 2>&1 || { echo "Requiring team-reflex/discord-php..."; composer require team-reflex/discord-php --with-all-dependencies --no-interaction; }
}

configure_supervisor() {
    echo "Configuring Supervisor for Discord Bot..."

    if ! command -v supervisorctl >/dev/null 2>&1; then
        echo "Supervisor not found. Attempting to install..."
        if [ -f /etc/debian_version ]; then
            apt-get update -y && apt-get install -y supervisor
            systemctl enable supervisor 2>/dev/null || true
            systemctl start supervisor 2>/dev/null || service supervisor start 2>/dev/null || true
        elif [ -f /etc/redhat-release ]; then
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y supervisor
            else
                yum install -y supervisor
            fi
            systemctl enable supervisor
            systemctl start supervisor
        elif [ -f /etc/arch-release ]; then
            pacman -S --noconfirm supervisor
            systemctl enable supervisor
            systemctl start supervisor
        elif [ -f /etc/alpine-release ]; then
            apk add supervisor
            rc-update add supervisord
            rc-service supervisord start
        elif [ -f /etc/os-release ] && grep -q "ID=opensuse" /etc/os-release; then
            zypper install -y supervisor
            systemctl enable supervisor
            systemctl start supervisor
        else
            echo "Warning: Unsupported OS for automatic Supervisor installation. Please install Supervisor manually."
        fi
    fi

    LOG_DIR="/var/log/pterodactyl"
    if [ ! -d "$LOG_DIR" ]; then
        echo "Creating log directory: $LOG_DIR"
        mkdir -p "$LOG_DIR"
        chown www-data:www-data "$LOG_DIR"
        chmod 755 "$LOG_DIR"
    else
        echo "Log directory exists: $LOG_DIR"
    fi

    BAD_CONFIG="/etc/supervisor/conf.d/pterodactly-discord.conf"
    if [ -f "$BAD_CONFIG" ]; then
        echo "Removing malformed config file: $BAD_CONFIG"
        rm -f "$BAD_CONFIG"
    fi

    CONFIG_FILE="/etc/supervisor/conf.d/pterodactyl-discord.conf"
    echo "Writing supervisor config to $CONFIG_FILE"

    cat <<EOF > "$CONFIG_FILE"
[program:pterodactyl-discord]
command=php $PANEL_PATH/artisan rolexdev:discord:run
user=www-data
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/pterodactyl/discord-bot.err.log
stderr_logfile_maxbytes=10MB
stderr_logfile_backups=3
stdout_logfile=/var/log/pterodactyl/discord-bot.out.log
stdout_logfile_maxbytes=10MB
stdout_logfile_backups=3
EOF

    if [ -f "$CONFIG_FILE" ]; then
        echo "Supervisor configuration created successfully at $CONFIG_FILE."
    else
        echo "Error: Failed to create supervisor configuration at $CONFIG_FILE."
        return 1
    fi

    echo "Reloading Supervisor..."
    supervisorctl reread || true
    supervisorctl update || true
    
    if supervisorctl status pterodactyl-discord | grep -q "RUNNING"; then
        echo "Restarting pterodactyl-discord process..."
        supervisorctl restart pterodactyl-discord
    else
        echo "Starting pterodactyl-discord process..."
        supervisorctl start pterodactyl-discord || true
    fi

    echo "Discord Bot process configured and running."
}

setup_logrotate() {
    local LOGROTATE_FILE="/etc/logrotate.d/pterodactyl"
    echo "Configuring logrotate for Pterodactyl logs..."

    local DESIRED_CONTENT
    DESIRED_CONTENT=$(cat <<LOGROTATE
/var/log/pterodactyl/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}

${PANEL_PATH}/storage/logs/laravel-*.log {
    daily
    size 50M
    rotate 3
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
    su www-data www-data
}
LOGROTATE
)

    if [[ -f "$LOGROTATE_FILE" ]]; then
        local EXISTING_CONTENT
        EXISTING_CONTENT=$(cat "$LOGROTATE_FILE")
        if [[ "$EXISTING_CONTENT" == "$DESIRED_CONTENT" ]]; then
            echo "Logrotate config already up to date at $LOGROTATE_FILE â€” skipping write."
            logrotate -f "$LOGROTATE_FILE" 2>/dev/null || true
            return
        else
            echo "Logrotate config exists but content differs â€” updating $LOGROTATE_FILE"
        fi
    else
        echo "Logrotate config not found â€” creating $LOGROTATE_FILE"
    fi

    printf '%s\n' "$DESIRED_CONTENT" > "$LOGROTATE_FILE"
    echo "Logrotate configured at $LOGROTATE_FILE"
    logrotate -f "$LOGROTATE_FILE" 2>/dev/null || true
}

set_log_level() {
    local ENV_FILE="$PANEL_PATH/.env"
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "No .env file found at $ENV_FILE, skipping LOG_LEVEL check."
        return
    fi
    local CURRENT_LEVEL
    CURRENT_LEVEL=$(grep -E '^LOG_LEVEL=' "$ENV_FILE" | cut -d= -f2 | tr -d '[:space:]')
    if [[ "$CURRENT_LEVEL" == "debug" ]]; then
        echo "LOG_LEVEL is 'debug' â€” changing to 'warning' to prevent storage/logs from filling the disk."
        sed -i 's/^LOG_LEVEL=debug$/LOG_LEVEL=warning/' "$ENV_FILE"
        echo "LOG_LEVEL updated to 'warning'."
    else
        echo "LOG_LEVEL is '${CURRENT_LEVEL:-not set}' â€” no change needed."
    fi
}

ensure_php84() {
    local TARGET="8.4"
    local FPM_SOCK="/run/php/php8.4-fpm.sock"

    echo "=== Ensuring PHP ${TARGET} is available for Pterodactyl ==="

    if ! command -v "php${TARGET}" >/dev/null 2>&1; then
        echo "PHP ${TARGET} not found. Installing..."

        if command -v apt-get >/dev/null 2>&1; then
            echo "Refreshing GPG keys for PHP to prevent expired key errors on Debian..."
            rm -f /etc/apt/trusted.gpg.d/php.gpg /usr/share/keyrings/deb.sury.org-php.gpg 2>/dev/null || true
            apt-key del B188E2B695BD4743 2>/dev/null || true
            if command -v curl >/dev/null 2>&1; then
                curl -sSLo /tmp/php.gpg https://packages.sury.org/php/apt.gpg 2>/dev/null || true
            else
                wget -qO /tmp/php.gpg https://packages.sury.org/php/apt.gpg 2>/dev/null || true
            fi
            if [[ -f /tmp/php.gpg ]]; then
                install -o root -g root -m 644 /tmp/php.gpg /etc/apt/trusted.gpg.d/php.gpg
                install -o root -g root -m 644 /tmp/php.gpg /usr/share/keyrings/deb.sury.org-php.gpg
                rm -f /tmp/php.gpg
            fi
            
            if command -v gpg >/dev/null 2>&1; then
                if command -v curl >/dev/null 2>&1; then
                    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg 2>/dev/null | gpg --dearmor -yes -o /etc/apt/trusted.gpg.d/yarn.gpg 2>/dev/null || true
                fi
            fi
            
            echo "Clearing apt cache..."
            rm -rf /var/lib/apt/lists/*
            apt-get clean
        fi

        if ! grep -rq "ondrej/php\|packages.sury.org/php" /etc/apt/sources.list /etc/apt/sources.list.d/ /etc/apt/sources.list.d/*.sources 2>/dev/null; then
            if command -v add-apt-repository >/dev/null 2>&1; then
                add-apt-repository -y ppa:ondrej/php
            else
                echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" \
                    > /etc/apt/sources.list.d/php.list
            fi
        fi

        apt-get update -y
        apt-get install -y \
            php8.4 php8.4-cli php8.4-fpm \
            php8.4-bcmath php8.4-curl php8.4-gd \
            php8.4-mbstring php8.4-mysql php8.4-opcache \
            php8.4-xml php8.4-zip
    else
        echo "PHP ${TARGET} already installed."
        if ! command -v "php-fpm${TARGET}" >/dev/null 2>&1; then
            echo "php-fpm${TARGET} not found. Installing..."
            apt-get update -y
            apt-get install -y php8.4-fpm
        fi
    fi

    if command -v update-alternatives >/dev/null 2>&1; then
        update-alternatives --set php /usr/bin/php8.4 2>/dev/null || true
        update-alternatives --set php-config /usr/bin/php-config8.4 2>/dev/null || true
    fi

    local EXT_DIR
    EXT_DIR=$(php8.4 -r "echo ini_get('extension_dir');" 2>/dev/null)
    if [[ -z "$EXT_DIR" ]]; then
        EXT_DIR=$(php8.4 -i 2>/dev/null | grep "^extension_dir" | head -1 | awk -F'=>' '{print $2}' | xargs)
    fi
    if [[ -z "$EXT_DIR" ]]; then
        EXT_DIR="/usr/lib/php/$(php8.4 -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo '8.4')"
    fi
    local LOADER_TARGET="${EXT_DIR}/ioncube_loader_lin_8.4.so"

    if ! php8.4 -m 2>/dev/null | grep -q "ionCube Loader"; then
        echo "Installing IonCube loader for PHP ${TARGET}..."
        local ARCH
        ARCH=$(uname -m)
        local IC_URL
        if [[ "$ARCH" == "aarch64" ]]; then
            IC_URL="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz"
        else
            IC_URL="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
        fi

        local IC_TMP
        IC_TMP=$(mktemp -d)

        local LOCAL_SO
        LOCAL_SO=$(find "$SCRIPT_DIR" -maxdepth 1 -name "ioncube_loader_lin_8.4.so" 2>/dev/null | head -1)
        local LOCAL_TAR
        LOCAL_TAR=$(find "$SCRIPT_DIR" -maxdepth 1 -name "ioncube_loaders_lin_*.tar.gz" 2>/dev/null | head -1)

        if [[ -n "$LOCAL_SO" ]]; then
            echo "Found local ioncube_loader_lin_8.4.so in ${SCRIPT_DIR} â€” skipping download."
            cp "$LOCAL_SO" "${IC_TMP}/ioncube_loader_lin_8.4.so"
            mkdir -p "${IC_TMP}/ioncube"
            cp "$LOCAL_SO" "${IC_TMP}/ioncube/ioncube_loader_lin_8.4.so"
        elif [[ -n "$LOCAL_TAR" ]]; then
            echo "Found local IonCube tarball ${LOCAL_TAR} â€” skipping download."
            cp "$LOCAL_TAR" "${IC_TMP}/ioncube.tar.gz"
            tar -xzf "${IC_TMP}/ioncube.tar.gz" -C "$IC_TMP"
        else
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL -o "${IC_TMP}/ioncube.tar.gz" "$IC_URL"
            else
                wget -q -O "${IC_TMP}/ioncube.tar.gz" "$IC_URL"
            fi
            tar -xzf "${IC_TMP}/ioncube.tar.gz" -C "$IC_TMP"
        fi

        local LOADER_SRC="${IC_TMP}/ioncube/ioncube_loader_lin_8.4.so"
        if [[ -f "$LOADER_SRC" ]]; then
            mkdir -p "$EXT_DIR"
            cp "$LOADER_SRC" "$LOADER_TARGET"
            chmod 644 "$LOADER_TARGET"
            if file "$LOADER_TARGET" 2>/dev/null | grep -q "missing section headers" || \
               ! php8.4 -n -d "zend_extension=$LOADER_TARGET" -r "echo 1;" >/dev/null 2>&1; then
                echo "WARNING: IonCube .so appears corrupt, retrying download..." >&2
                rm -f "$LOADER_TARGET"
                local IC_TMP2
                IC_TMP2=$(mktemp -d)
                if command -v curl >/dev/null 2>&1; then
                    curl -fsSL -o "${IC_TMP2}/ioncube.tar.gz" "$IC_URL"
                else
                    wget -q -O "${IC_TMP2}/ioncube.tar.gz" "$IC_URL"
                fi
                tar -xzf "${IC_TMP2}/ioncube.tar.gz" -C "$IC_TMP2"
                if [[ -f "${IC_TMP2}/ioncube/ioncube_loader_lin_8.4.so" ]]; then
                    cp "${IC_TMP2}/ioncube/ioncube_loader_lin_8.4.so" "$LOADER_TARGET"
                    chmod 644 "$LOADER_TARGET"
                    echo "IonCube loader re-downloaded and installed successfully."
                else
                    echo "ERROR: Failed to re-download IonCube loader." >&2
                fi
                rm -rf "$IC_TMP2"
            fi
        else
            echo "WARNING: Could not find ioncube_loader_lin_8.4.so in downloaded archive." >&2
        fi
        rm -rf "$IC_TMP"
    else
        echo "IonCube loader already installed for PHP ${TARGET}."
    fi

    for CONF_DIR in "/etc/php/8.4/cli/conf.d" "/etc/php/8.4/fpm/conf.d"; do
        if [[ -d "$CONF_DIR" ]]; then
            cat > "${CONF_DIR}/00-ioncube.ini" <<INIEOF
zend_extension="${LOADER_TARGET}"
; Disable JIT to prevent IonCube + OPcache JIT conflict (FPM worker deadlock)
opcache.jit=0
opcache.jit_buffer_size=0
INIEOF
            echo "Wrote ${CONF_DIR}/00-ioncube.ini"
        fi
    done

    local NGINX_CONFS=()
    if [[ -f "/etc/nginx/sites-available/pterodactyl.conf" ]]; then
        NGINX_CONFS+=("/etc/nginx/sites-available/pterodactyl.conf")
    fi
    if [[ -f "/etc/nginx/sites-enabled/pterodactyl.conf" ]]; then
        NGINX_CONFS+=("/etc/nginx/sites-enabled/pterodactyl.conf")
    fi
    while IFS= read -r conf; do
        if [[ -n "$conf" ]]; then
            NGINX_CONFS+=("$conf")
        fi
    done < <(grep -rl "root /var/www/pterodactyl/public" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ /etc/nginx/conf.d/ 2>/dev/null || true)

    if [[ ${#NGINX_CONFS[@]} -eq 0 ]]; then
        echo "WARNING: Could not locate pterodactyl nginx config. Update fastcgi_pass to ${FPM_SOCK} manually." >&2
    else
        local NGINX_UPDATED=0
        local PROCESSED_CONFS=()
        for CONF_PATH in "${NGINX_CONFS[@]}"; do
            local REAL_CONF
            REAL_CONF=$(readlink -f "$CONF_PATH")
            
            local ALREADY_PROCESSED=0
            for PC in "${PROCESSED_CONFS[@]}"; do
                if [[ "$PC" == "$REAL_CONF" ]]; then
                    ALREADY_PROCESSED=1
                    break
                fi
            done
            if [[ $ALREADY_PROCESSED -eq 1 ]]; then
                continue
            fi
            PROCESSED_CONFS+=("$REAL_CONF")

            if grep -qE "unix:/run/php/php[0-9]+\.[0-9]+-fpm\.sock|unix:/run/php/php-fpm[0-9]+\.[0-9]+\.sock" "$REAL_CONF"; then
                sed -i -E "s|unix:/run/php/php[0-9]+\.[0-9]+-fpm\.sock|unix:${FPM_SOCK}|g" "$REAL_CONF"
                sed -i -E "s|unix:/run/php/php-fpm[0-9]+\.[0-9]+\.sock|unix:${FPM_SOCK}|g" "$REAL_CONF"
                echo "Updated nginx config ${REAL_CONF} to use ${FPM_SOCK}"
                NGINX_UPDATED=1
            else
                echo "No update needed for ${REAL_CONF} (no matching php-fpm socket found to replace or already up to date)."
            fi
        done

        if [[ $NGINX_UPDATED -eq 1 ]]; then
            if nginx -t >/dev/null 2>&1; then
                systemctl restart nginx 2>/dev/null || service nginx restart 2>/dev/null || true
                echo "Nginx reloaded."
            else
                echo "WARNING: nginx config test failed after socket update. Please check your Nginx configs." >&2
            fi
        fi
    fi

    if ! systemctl restart php8.4-fpm 2>/dev/null; then
        service php8.4-fpm restart 2>/dev/null || echo "WARNING: Could not restart php8.4-fpm." >&2
    fi
    echo "=== PHP ${TARGET} setup complete ==="
}

install_ioncube_loader() {
    echo "Checking IonCube Loader installation..."

    if php8.4 -m 2>/dev/null | grep -q "ionCube Loader"; then
        echo "IonCube Loader is already installed and loaded for PHP 8.4."
        return 0
    fi

    echo "IonCube Loader NOT found for PHP 8.4. Attempting automatic installation..."

    detect_php_version() {
        echo "8.4"
    }

    PHP_VERSION=$(detect_php_version)
    echo "Target PHP version for IonCube: $PHP_VERSION"

    ARCH=$(uname -m)
    echo "Detected CPU architecture: $ARCH"

    if [[ "$ARCH" == "aarch64" ]]; then
        DOWNLOAD_URL="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_aarch64.tar.gz"
    else
        DOWNLOAD_URL="https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
    fi

    TEMP_DIR=$(mktemp -d)
    echo "Downloading IonCube Loaders from $DOWNLOAD_URL to $TEMP_DIR..."
    
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$TEMP_DIR/ioncube.tar.gz" "$DOWNLOAD_URL"
    else
        wget -q -O "$TEMP_DIR/ioncube.tar.gz" "$DOWNLOAD_URL"
    fi

    tar -xzf "$TEMP_DIR/ioncube.tar.gz" -C "$TEMP_DIR"
    
    LOADER_FILE="$TEMP_DIR/ioncube/ioncube_loader_lin_${PHP_VERSION}.so"
    
    if [[ ! -f "$LOADER_FILE" ]]; then
        echo "Error: Could not find loader file for PHP $PHP_VERSION at $LOADER_FILE"
        rm -rf "$TEMP_DIR"
        return 1
    fi

    EXTENSION_DIR=$(php -i | grep "extension_dir" | head -1 | awk -F'=>' '{print $2}' | xargs)
    
    if command -v "php$PHP_VERSION" >/dev/null 2>&1; then
        EXTENSION_DIR=$("php$PHP_VERSION" -i | grep "extension_dir" | head -1 | awk -F'=>' '{print $2}' | xargs)
    fi

    TARGET_FILE="$EXTENSION_DIR/ioncube_loader_lin_${PHP_VERSION}.so"

    echo "Copying loader to extension directory: $TARGET_FILE"
    mkdir -p "$EXTENSION_DIR"
    cp "$LOADER_FILE" "$TARGET_FILE"
    chmod 644 "$TARGET_FILE"
    
    INI_NAME="00-ioncube.ini"
    
    CONFIG_PATHS=("/etc/php/$PHP_VERSION/cli/conf.d" "/etc/php/$PHP_VERSION/fpm/conf.d")
    
    if [[ -d "/etc/php.d" ]]; then
         CONFIG_PATHS+=("/etc/php.d")
    fi
    
    for conf_dir in "${CONFIG_PATHS[@]}"; do
        if [[ -d "$conf_dir" ]]; then
            cat > "$conf_dir/$INI_NAME" <<IONCUBE_INI
zend_extension="$TARGET_FILE"
; Disable JIT to prevent IonCube + OPcache JIT conflict (FPM worker deadlock)
opcache.jit=0
opcache.jit_buffer_size=0
IONCUBE_INI
            echo "Created configuration at $conf_dir/$INI_NAME"
        fi
    done

    rm -rf "$TEMP_DIR"

    echo "Restarting PHP-FPM and Web Server..."
    if ! systemctl restart "php${PHP_VERSION}-fpm" 2>/dev/null; then
        if ! systemctl restart "php-fpm${PHP_VERSION}" 2>/dev/null; then
            if ! systemctl restart php-fpm 2>/dev/null; then
                service "php${PHP_VERSION}-fpm" restart 2>/dev/null || \
                service php-fpm restart 2>/dev/null || \
                echo "Warning: Could not restart PHP-FPM automatically. Please restart it manually."
            fi
        fi
    fi
    
    if systemctl is-active --quiet nginx; then
        systemctl restart nginx
    elif systemctl is-active --quiet apache2; then
        systemctl restart apache2
    elif systemctl is-active --quiet httpd; then
         systemctl restart httpd
    fi

    if command -v "php$PHP_VERSION" >/dev/null 2>&1; then
         if "php$PHP_VERSION" -m | grep -q "ionCube Loader"; then
            echo "Success: IonCube Loader installed and loaded for PHP $PHP_VERSION."
            return 0
         fi
    fi

    if php -m | grep -q "ionCube Loader"; then
        echo "Success: IonCube Loader installed and loaded (verified via default CLI)."
    else
        echo "Warning: Verification failed. Please check 'php -m' or 'php$PHP_VERSION -m' manually."
    fi
}


restore_backup() {
    echo "Finding available backups..."
    BACKUPS=($(find /var/www -name "pterodactyl_backup_*.tar.gz" | sort))
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo "No backups found."
        return
    fi
    echo "Available backups:"
    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1))) ${BACKUPS[$i]}"
    done
    read -rp "Select a backup to restore (1-${#BACKUPS[@]}): " CHOICE
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt ${#BACKUPS[@]} ]; then
        echo "Invalid choice."
        return
    fi
    SELECTED="${BACKUPS[$((CHOICE-1))]}"
    read -rp "Are you sure you want to restore from $SELECTED? This will overwrite the current panel. (y/N): " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Restoring from $SELECTED..."
        cd /var/www || exit
        mv pterodactyl "pterodactyl_old_$(date +%Y%m%d_%H%M%S)"
        tar -xzf "$SELECTED"
        set_permissions
        fix_cron
        clear_cache
        echo "Restore completed."
    else
        echo "Restore cancelled."
    fi
}

configure_nginx_gzip() {
    echo "Checking Nginx configuration for advanced gzip support..."
    
    if ! command -v nginx >/dev/null 2>&1; then
        echo "Nginx not installed. Skipping gzip configuration."
        return
    fi

    NGINX_CONF=""
    if [ -f "/etc/nginx/sites-available/pterodactyl.conf" ]; then
        NGINX_CONF="/etc/nginx/sites-available/pterodactyl.conf"
    elif [ -f "/etc/nginx/sites-enabled/pterodactyl.conf" ]; then
        NGINX_CONF="/etc/nginx/sites-enabled/pterodactyl.conf"
    else
        detected=$(grep -rl "root /var/www/pterodactyl/public" /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ /etc/nginx/conf.d/ 2>/dev/null | head -n 1)
        if [ -n "$detected" ]; then
            NGINX_CONF="$detected"
        fi
    fi

    if [ -z "$NGINX_CONF" ]; then
        echo "Warning: Pterodactyl Nginx configuration file not found. Skipping gzip injection."
        return
    fi

    echo "Found Pterodactyl Nginx config at $NGINX_CONF"

    if grep -q "gzip_static on;" "$NGINX_CONF"; then
        echo "Advanced gzip configuration is already present in $NGINX_CONF."
        return
    fi
    
    echo "Injecting gzip configuration into $NGINX_CONF..."
    
    cp "$NGINX_CONF" "${NGINX_CONF}.bak.gzip"
    awk '
    { print }
    /root \/var\/www\/pterodactyl\/public;/ {
        if (!injected) {
            print "    gzip on;"
            print "    gzip_static on;"
            print "    gzip_vary on;"
            print "    gzip_proxied any;"
            print "    gzip_comp_level 6;"
            print "    gzip_types text/plain text/css text/xml application/javascript image/svg+xml;"
            injected=1
        }
    }
    ' "$NGINX_CONF" > "${NGINX_CONF}.tmp" && mv "${NGINX_CONF}.tmp" "$NGINX_CONF"

    if nginx -t >/dev/null 2>&1; then
        echo "Nginx configuration test passed. Reloading Nginx..."
        systemctl reload nginx || systemctl restart nginx
        echo "Nginx reloaded with precise gzip configurations."
    else
        echo "Warning: Nginx configuration test failed after injecting gzip."
        echo "Restoring original configuration..."
        mv "${NGINX_CONF}.bak.gzip" "$NGINX_CONF"
        systemctl reload nginx || true
    fi
}



case $OPTION in
1)
    echo "--- Starting HyperV1 Installation ---"
    ensure_php84
    manage_backups
    backup_hyperv1
    backup_panel
    remove_old_assets
    install_hyperv1_files
    
    install_ioncube_loader
    install_dependencies
    migrate_db
    clear_cache
    set_permissions
    set_log_level
    fix_cron
    set_fetch_permissions
    configure_supervisor
    setup_logrotate
    configure_reverse_proxy_permissions
    configure_nginx_gzip
    echo "---- HyperV1 Installation Completed ----"
    ;;
2)
    echo "--- Starting HyperV1 Upgrade ---"
    ensure_php84
    manage_backups
    backup_hyperv1
    backup_panel
    remove_old_assets
    install_hyperv1_files
    install_ioncube_loader
    install_dependencies
    
    migrate_db
    clear_cache
    set_permissions
    set_log_level
    fix_cron
    set_fetch_permissions
    configure_supervisor
    setup_logrotate
    configure_reverse_proxy_permissions
    configure_nginx_gzip
    echo "---- HyperV1 Upgrade Completed ----"
    ;;
3)
    echo "--- Starting Restore from Backup ---"
    restore_backup
    echo "---- Restore Completed ----"
    ;;
*)
    echo "Invalid option. Please choose 1, 2, or 3."
    exit 1
    ;;
esac

echo ""
echo "ðŸŽ‰ Process Finished Successfully!"
