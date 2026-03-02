
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
    echo -e " ║  ${BG_BLUE}${W} 🐲 JEXACTYL MANAGER ${N}${C}                                 ║"
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

# ==========================================
# 🚀 ACTIONS
# ==========================================

install_panel() {
    header
    echo -e "\n${G} [ INSTALLATION MODE ] ${N}"
    echo -e " ${W}Starting Jexactyl Installation/Update process...${N}\n"
    bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/panel/Jexactyl/install.sh)
    echo -e " ${Y}⚠ No command configured yet. Add script in 'install_panel' function.${N}"
    pause
}

uninstall_panel() {
    header
    echo -e "\n${R} [ MAINTENANCE MODE ] ${N}"
    echo -e " ${W}Starting Uninstall / Backup Restore...${N}\n"
    echo ">>> Stopping Panel service..."
    systemctl stop panel.service 2>/dev/null || true
    systemctl disable panel.service 2>/dev/null || true
    rm -f /etc/systemd/system/panel.service
    systemctl daemon-reload

    echo ">>> Removing cronjob..."
    crontab -l | grep -v 'php /var/www/jexactyl/artisan schedule:run' | crontab - || true

    echo ">>> Removing files..."
    rm -rf /var/www/jexactyl
    echo ">>> Dropping database..."
    mysql -u root -e "DROP DATABASE IF EXISTS jexactyl;"
    mysql -u root -e "DROP USER IF EXISTS 'jexactyl'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"
    echo ">>> Cleaning nginx..."
    rm -f /etc/nginx/sites-enabled/panel.conf
    rm -f /etc/nginx/sites-available/panel.conf
    systemctl reload nginx || true
    
    
    echo -e " ${Y}⚠ No command configured yet. Add script in 'uninstall_panel' function.${N}"
    pause
}

# ==========================================
# 🖥️ MAIN MENU
# ==========================================
while true; do
  header
  echo -e "${W} SELECT AN OPERATION:${N}\n"

  echo -e "  ${B}[ 1 ]${N}  🚀  Install"
  echo -e "  ${Y}[ 2 ]${N}  🚀  Create admin user"
  echo -e "  ${G}[ 3 ]${N}  🚀  update"
  echo -e "  ${G}[ 4 ]${N}  🚀  Migration"
  echo -e "  ${R}[ 5 ]${N}  ♻️  Uninstall"
  echo -e ""
  echo -e "  ${R}[ 0 ]${N}  ❌  Exit Manager"
  
  echo -e "\n${C} ──────────────────────────────────────────────────────────${N}"
  read -p " 👉 Select Option: " choice

  case $choice in
    1) install_panel ;;
    5) uninstall_panel ;;
    2)
       echo -e "\n${M} 👋  Create admin user.${N}" 
       cd /var/www/jexactyl && php artisan p:user:make
       ;;
    3)
       echo -e "\n${M} 👋  Updating.${N}" 
       cd /var/www/jexactyl
       php artisan down
       curl -L https://github.com/jexactyl/jexactyl/releases/latest/download/panel.tar.gz | tar -xzv
       chmod -R 755 storage/* bootstrap/cache
       COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
       php artisan migrate --seed --force
       chown -R www-data:www-data /var/www/jexactyl/*
       sudo systemctl restart panel.service 
       php artisan up
       ;; 
    4)
       bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/panel/Jexactyl/Migration.sh)
       ;;
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
