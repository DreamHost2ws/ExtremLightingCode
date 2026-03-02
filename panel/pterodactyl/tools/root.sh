#!/bin/bash

# ==================================================
#  SSH COMMANDER v3.0 | ACCESS CONTROL SYSTEM
# ==================================================

# --- THEME & COLORS ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[1;90m'
NC='\033[0m' # No Color

CONFIG_FILE="/etc/ssh/sshd_config"
BACKUP_FILE="/etc/ssh/sshd_config.bak"

# --- HELPER FUNCTIONS ---

# Pretty print status messages
msg_info() { echo -e "  ${BLUE}➜${NC}  $1"; }
msg_ok()   { echo -e "  ${GREEN}✔${NC}  $1"; }
msg_warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
msg_err()  { echo -e "  ${RED}✖${NC}  $1"; }

# Get status of a specific SSH config parameter
get_conf_status() {
    local param=$1
    local default=$2
    # Find parameter, ignore comments, take last occurrence
    local val=$(grep -E "^${param}" "$CONFIG_FILE" | tail -n 1 | awk '{print $2}')
    
    if [[ -z "$val" ]]; then val="$default"; fi
    
    if [[ "$val" == "yes" ]]; then
        echo -e "${GREEN}[ ON ]${NC}"
    else
        echo -e "${RED}[ OFF ]${NC}"
    fi
}

get_ssh_port() {
    local port=$(grep -E "^Port" "$CONFIG_FILE" | head -n 1 | awk '{print $2}')
    if [[ -z "$port" ]]; then echo "22 (Default)"; else echo "$port"; fi
}

# --- HEADER UI ---

draw_header() {
    clear
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    local active_sessions=$(who | grep pts | wc -l)
    
    # Service Status
    local srv_stat="${RED}STOPPED${NC}"
    if systemctl is-active --quiet ssh; then srv_stat="${GREEN}ONLINE${NC}"; fi
    
    # Config Status
    local root_login=$(get_conf_status "PermitRootLogin" "prohibit-password")
    local pass_auth=$(get_conf_status "PasswordAuthentication" "no")
    local current_port=$(get_ssh_port)

    echo -e "${PURPLE}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}║${NC}      ${WHITE}SSH COMMANDER${NC} ${GRAY}::${NC} ${CYAN}SERVER ACCESS CONTROL SYSTEM${NC}                 ${PURPLE}║${NC}"
    echo -e "${PURPLE}══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}║${NC} ${GRAY}SYSTEM:${NC} ${WHITE}$hostname${NC}  ${GRAY}IP:${NC} ${WHITE}$ip${NC}"
    echo -e "${PURPLE}║${NC} ${GRAY}STATUS:${NC} $srv_stat   ${GRAY}PORT:${NC} ${WHITE}$current_port${NC}   ${GRAY}SESSIONS:${NC} ${YELLOW}$active_sessions${NC}"
    echo -e "${PURPLE}──────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${PURPLE}║${NC} ${CYAN}SECURITY CONFIGURATION:${NC}"
    echo -e "${PURPLE}║${NC}   ${GRAY}●${NC} Root Login      : $root_login"
    echo -e "${PURPLE}║${NC}   ${GRAY}●${NC} Password Auth   : $pass_auth"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# --- ACTIONS ---

enable_access() {
    echo -e "${GRAY}  ──────────────────────────────────────────${NC}"
    msg_info "Unlocking Server Access..."
    
    # Backup
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    # Modify
    sed -i '/^PermitRootLogin/d' "$CONFIG_FILE"
    sed -i '/^PasswordAuthentication/d' "$CONFIG_FILE"
    echo "PermitRootLogin yes" >> "$CONFIG_FILE"
    echo "PasswordAuthentication yes" >> "$CONFIG_FILE"
    
    msg_ok "Config Updated (Root: YES, Pass: YES)"
    
    # Restart
    msg_info "Reloading SSH Daemon..."
    systemctl restart ssh
    
    msg_ok "Service Restarted."
    echo ""
    echo -e "${YELLOW}  IMPORTANT: Ensure a strong Root Password is set!${NC}"
    read -p "  Press Enter to continue..."
}

secure_lockdown() {
    echo -e "${GRAY}  ──────────────────────────────────────────${NC}"
    msg_warn "LOCKDOWN MODE INITIATED"
    echo -e "  This will ${RED}DISABLE${NC} Root Login & Password Auth."
    echo -e "  Ensure you have SSH Keys configured before proceeding."
    echo ""
    echo -ne "${PURPLE}  ➤ Confirm Lockdown? (y/N): ${NC}"
    read confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Modify
        sed -i '/^PermitRootLogin/d' "$CONFIG_FILE"
        sed -i '/^PasswordAuthentication/d' "$CONFIG_FILE"
        echo "PermitRootLogin no" >> "$CONFIG_FILE"
        echo "PasswordAuthentication no" >> "$CONFIG_FILE"
        
        systemctl restart ssh
        echo ""
        msg_ok "Server Secured (Key-Only Access)."
    else
        msg_info "Operation Cancelled."
    fi
    read -p "  Press Enter to continue..."
}

set_root_pass() {
    echo -e "${GRAY}  ──────────────────────────────────────────${NC}"
    msg_info "Changing Root Password..."
    echo ""
    passwd root
    echo ""
    if [ $? -eq 0 ]; then
        msg_ok "Password Updated Successfully."
    else
        msg_err "Password Change Failed."
    fi
    read -p "  Press Enter to continue..."
}

restore_backup() {
    echo -e "${GRAY}  ──────────────────────────────────────────${NC}"
    if [ -f "$BACKUP_FILE" ]; then
        msg_info "Found backup file..."
        cp "$BACKUP_FILE" "$CONFIG_FILE"
        systemctl restart ssh
        msg_ok "Configuration Restored to Backup state."
    else
        msg_err "No backup file found (.bak)"
    fi
    read -p "  Press Enter to continue..."
}

# --- INITIAL CHECK ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root.${NC}"
    exit 1
fi

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "  ${WHITE}ACCESS CONTROLS:${NC}"
    echo -e "  ${GREEN}[1]${NC} Enable Root & Passwords   ${GRAY}(Open Access)${NC}"
    echo -e "  ${RED}[2]${NC} Secure Lockdown           ${GRAY}(SSH Keys Only)${NC}"
    echo -e ""
    echo -e "  ${WHITE}MANAGEMENT:${NC}"
    echo -e "  ${YELLOW}[3]${NC} Set Root Password         ${GRAY}(Change Creds)${NC}"
    echo -e "  ${BLUE}[4]${NC} Restore Backup Config     ${GRAY}(Undo Changes)${NC}"
    echo -e ""
    echo -e "  ${GRAY}[0] Exit Commander${NC}"
    echo ""
    echo -ne "${PURPLE}  root@ssh:~# ${NC}"
    read option
    
    case $option in
        1) enable_access ;;
        2) secure_lockdown ;;
        3) set_root_pass ;;
        4) restore_backup ;;
        0) clear; exit 0 ;;
        *) msg_err "Invalid Option"; sleep 1 ;;
    esac
done
