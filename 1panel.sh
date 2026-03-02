#!/bin/bash

# ==================================================
#  1PANEL MANAGER | LightPlays
# ==================================================

# --- COLORS & STYLES ---
C_RESET='\033[0m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_PURPLE='\033[1;35m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'

# --- UI DRAWING FUNCTIONS ---

draw_header() {
    clear
    local hostname=$(hostname)
    local ip=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    
    # Check 1Panel Status
    local status="${C_GRAY}NOT INSTALLED${C_RESET}"
    local port_info=""
    
    if command -v 1pctl &>/dev/null; then
        if systemctl is-active --quiet 1panel; then
            status="${C_GREEN}● RUNNING${C_RESET}"
            # Attempt to grab port from config or default to 10086
            port_info="${C_WHITE}http://$ip:10086${C_RESET}"
        else
            status="${C_RED}● STOPPED${C_RESET}"
        fi
    fi

    echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}${C_PURPLE}💠 1PANEL DASHBOARD MANAGER v2.0${C_RESET}                                   ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}HOST:${C_RESET} ${C_WHITE}$hostname${C_RESET}   ${C_GRAY}IP:${C_RESET} ${C_WHITE}$ip${C_RESET}                                   ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_CYAN}SERVICE STATUS:${C_RESET} $status       ${C_CYAN}ACCESS:${C_RESET} $port_info          ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

print_status() {
    local type=$1
    local message=$2
    case $type in
        "INFO")    echo -e " ${C_BLUE}➜${C_RESET} ${C_WHITE}$message${C_RESET}" ;;
        "WARN")    echo -e " ${C_YELLOW}⚠${C_RESET} ${C_YELLOW}$message${C_RESET}" ;;
        "ERROR")   echo -e " ${C_RED}✖${C_RESET} ${C_RED}$message${C_RESET}" ;;
        "SUCCESS") echo -e " ${C_GREEN}✔${C_RESET} ${C_GREEN}$message${C_RESET}" ;;
        "INPUT")   echo -ne " ${C_PURPLE}➤${C_RESET} ${C_CYAN}$message${C_RESET}" ;;
    esac
}

pause() {
    echo ""
    read -p "Press Enter to return..."
}

# --- ACTIONS ---

install_1panel() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    print_status "INFO" "Starting Official Installer..."
    
    if command -v 1pctl &>/dev/null; then
        print_status "WARN" "1Panel is already installed."
        read -p "$(print_status "INPUT" "Re-install anyway? (y/N): ")" confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return; fi
    fi

    # Run Official Script
    curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh | bash
    
    echo ""
    print_status "SUCCESS" "Installation Process Finished!"
    pause
}

uninstall_1panel() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_RED}⚠️  DANGER ZONE: UNINSTALL${C_RESET}"
    
    if ! command -v 1pctl &>/dev/null; then
        print_status "ERROR" "1Panel is not installed."
        pause
        return
    fi

    read -p "$(print_status "INPUT" "Completely remove 1Panel? (y/N): ")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "INFO" "Cancelled."
        pause; return
    fi
    
    print_status "INFO" "Running Uninstaller..."
    1pctl uninstall
    
    print_status "SUCCESS" "1Panel removed."
    pause
}

view_login_info() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    if command -v 1pctl &>/dev/null; then
        print_status "INFO" "Fetching User Info..."
        echo ""
        1pctl user-info
    else
        print_status "ERROR" "1Panel is not installed."
    fi
    pause
}

service_control() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    echo -e " ${C_WHITE}1) Start Service${C_RESET}"
    echo -e " ${C_WHITE}2) Stop Service${C_RESET}"
    echo -e " ${C_WHITE}3) Restart Service${C_RESET}"
    echo ""
    read -p "$(print_status "INPUT" "Select: ")" s_opt
    
    case $s_opt in
        1) systemctl start 1panel; print_status "SUCCESS" "Started." ;;
        2) systemctl stop 1panel; print_status "INFO" "Stopped." ;;
        3) systemctl restart 1panel; print_status "SUCCESS" "Restarted." ;;
        *) print_status "ERROR" "Invalid option." ;;
    esac
    pause
}

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "${C_WHITE} AVAILABLE ACTIONS:${C_RESET}"
    echo -e " ${C_GREEN}[1]${C_RESET} Install 1Panel         ${C_PURPLE}[3]${C_RESET} View Login Info"
    echo -e " ${C_RED}[2]${C_RESET} Uninstall 1Panel       ${C_BLUE}[4]${C_RESET} Service Control"
    echo -e " ${C_GRAY}[0]${C_RESET} Exit"
    echo ""
    
    read -p "$(print_status "INPUT" "Select Option: ")" option
    
    case $option in
        1) install_1panel ;;
        2) uninstall_1panel ;;
        3) view_login_info ;;
        4) service_control ;;
        0) 
            echo -e "\n${C_PURPLE}👋 Exiting...${C_RESET}"
            exit 0 
            ;;
        *) 
            print_status "ERROR" "Invalid Option." 
            sleep 1
            ;;
    esac
done
