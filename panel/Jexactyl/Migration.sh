
#!/bin/bash

# ==========================================
# 🐲 UI CONFIGURATION & COLORS
# ==========================================
# Colors
R="\e[31m"; G="\e[32m"; Y="\e[33m"
B="\e[34m"; M="\e[35m"; C="\e[36m"
W="\e[97m"; N="\e[0m"
BG_BLUE="\e[44m"

# Trap Ctrl+C
trap 'echo -e "\n${R} [!] Force exit detected.${N}"; exit 1' SIGINT

# ==========================================
# 🛠️ HELPER FUNCTIONS
# ==========================================

header() {
    clear
    echo -e "${C}"
    echo " ╔══════════════════════════════════════════════════════════╗"
    echo " ║                                                          ║"
    echo -e " ║  ${BG_BLUE}${W} 🐲 JEXACTYL MIGRATION ${N}${C}                                ║"
    echo " ║                                                          ║"
    echo " ╠══════════════════════════════════════════════════════════╣"
    echo -e " ║ ${B}User:${N} $(whoami)  ${B}Host:${N} $(hostname)  ${B}Date:${N} $(date +'%H:%M')   ${C}║"
    echo " ╚══════════════════════════════════════════════════════════╝"
    echo -e "${N}"
}

pause() {
    echo -e "\n${B} ──────────────────────────────────────────────────────────${N}"
    read -rp " ↩️  Press Enter to return..."
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
       echo -e "\n${R} [ERROR] This script must be run as root.${N}"
       exit 1
    fi
}

# ==========================================
# 🚀 ACTIONS
# ==========================================

install_update() {
    header
    echo -e "\n${G} [ INSTALLATION / UPDATE ] ${N}\n"

    # Backup
    echo -e " ${Y}📦 Creating backup...${N}"
    if [ -d "/var/www/pterodactyl" ]; then
        cp -R /var/www/pterodactyl /var/www/pterodactyl-backup
        echo -e " ${G}✔ Files backed up.${N}"
    else
        echo -e " ${R}⚠ Pterodactyl directory not found (Skipping file backup).${N}"
    fi
    
    # DB Backup (Optional check)
    echo -e " ${Y}🗄️ Dumping database...${N}"
    mysqldump -u root -p panel > /var/www/pterodactyl-backup/panel.sql 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e " ${G}✔ Database backed up.${N}"
    else
        echo -e " ${R}⚠ Database backup failed (Check MySQL credentials).${N}"
    fi

    # Update Process
    echo -e "\n ${C}⬇️  Downloading Jexactyl...${N}"
    mkdir -p /var/www/pterodactyl
    cd /var/www/pterodactyl || return
    php artisan down 2>/dev/null

    curl -L -o panel.tar.gz https://github.com/jexactyl/jexactyl/releases/latest/download/panel.tar.gz
    tar -xzvf panel.tar.gz >/dev/null && rm -f panel.tar.gz

    echo -e " ${C}🔧 Configuring permissions...${N}"
    chmod -R 755 storage/* bootstrap/cache
    
    echo -e " ${C}📦 Installing dependencies (Composer)...${N}"
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --quiet

    echo -e " ${C}🧹 Clearing cache & Migrating DB...${N}"
    php artisan optimize:clear
    php artisan migrate --seed --force

    echo -e " ${C}👤 Setting ownership...${N}"
    chown -R www-data:www-data /var/www/pterodactyl/*

    echo -e " ${C}🔄 Restarting Queue...${N}"
    php artisan queue:restart
    php artisan up

    echo -e "\n${G} [ SUCCESS ] Jexactyl Updated Successfully! ${N}"
    pause
}

uninstall_restore() {
    header
    echo -e "\n${R} [ RESTORE / REPAIR ] ${N}\n"

    if [ ! -d "/var/www/pterodactyl-backup" ]; then
        echo -e " ${R}❌ No backup found at /var/www/pterodactyl-backup!${N}"
        pause
        return
    fi

    echo -e " ${Y}⚠ Restoring Backup...${N}"
    cd /var/www/pterodactyl || return
    php artisan down 2>/dev/null
    
    echo -e " ${R}🗑️ Removing current files...${N}"
    rm -rf /var/www/pterodactyl
    
    echo -e " ${G}♻️  Restoring backup files...${N}"
    mv /var/www/pterodactyl-backup /var/www/pterodactyl
    cd /var/www/pterodactyl || return

    echo -e " ${C}🔧 Fixing permissions & dependencies...${N}"
    chmod -R 755 storage/* bootstrap/cache
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --quiet

    echo -e " ${C}🧹 Clearing cache...${N}"
    php artisan view:clear
    php artisan config:clear

    echo -e " ${C}📂 Running migrations...${N}"
    php artisan migrate --seed --force

    echo -e " ${C}👤 Setting ownership...${N}"
    chown -R www-data:www-data /var/www/pterodactyl/*

    echo -e " ${C}🔄 Restarting queue...${N}"
    php artisan queue:restart
    php artisan up

    echo -e "\n${G} [ SUCCESS ] Panel Restored & Online. ${N}"
    pause
}

# ==========================================
# 🖥️ MAIN MENU
# ==========================================
check_root

while true; do
  header
  echo -e "${W} SELECT AN OPERATION:${N}\n"

  echo -e "  ${G}[ 1 ]${N}  🚀  Install / Update Jexactyl"
  echo -e "  ${R}[ 2 ]${N}  ♻️   Uninstall / Restore Backup"
  echo -e ""
  echo -e "  ${R}[ 0 ]${N}  ❌  Exit Manager"
  
  echo -e "\n${C} ──────────────────────────────────────────────────────────${N}"
  read -p " 👉 Select Option: " choice

  case $choice in
    1) install_update ;;
    2) uninstall_restore ;;
    0) 
       echo -e "\n${M} 👋 Exiting Jexactyl Manager.${N}"
       exit 0 
       ;;
    *) 
       echo -e "\n${R} ❌ Invalid Option!${N}"
       sleep 1
       ;;
  esac
done
