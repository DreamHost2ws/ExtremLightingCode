#!/bin/bash

# ==================================================
#  CASAOS MANAGER | DASHBOARD UI
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
    local ip=$(hostname -I | awk '{print $1}')
    
    # Check CasaOS Status
    local status="${C_GRAY}NOT INSTALLED${C_RESET}"
    local access_url=""
    
    if command -v casaos &>/dev/null; then
        if systemctl is-active --quiet casaos; then
            status="${C_GREEN}● RUNNING${C_RESET}"
            access_url="${C_WHITE}http://$ip${C_RESET}"
        else
            status="${C_RED}● STOPPED${C_RESET}"
        fi
    fi

    echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}${C_PURPLE}🏠 CASAOS DASHBOARD MANAGER v2.0${C_RESET}                                  ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}HOST:${C_RESET} ${C_WHITE}$hostname${C_RESET}   ${C_GRAY}IP:${C_RESET} ${C_WHITE}$ip${C_RESET}                                   ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_CYAN}SERVICE STATUS:${C_RESET} $status       ${C_CYAN}URL:${C_RESET} $access_url               ${C_BLUE}║${C_RESET}"
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

install_casaos() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    print_status "INFO" "Starting Installation Sequence..."
    
    # Check if already installed
    if command -v casaos &>/dev/null; then
        print_status "WARN" "CasaOS seems to be already installed."
        read -p "$(print_status "INPUT" "Re-install anyway? (y/N): ")" confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return; fi
    fi

    # Run Official Installer
    print_status "INFO" "Downloading & Running Installer..."
    curl -fsSL https://get.casaos.io | bash
    
    echo ""
    print_status "SUCCESS" "Installation Completed!"
    pause
}

uninstall_casaos() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_RED}⚠️  DANGER ZONE: UNINSTALL${C_RESET}"
    echo -e "This will remove CasaOS, services, and configuration files."
    echo ""
    
    read -p "$(print_status "INPUT" "Are you sure? (y/N): ")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "INFO" "Cancelled."
        pause; return
    fi
    
    print_status "INFO" "Running Uninstaller..."
    if command -v casaos-uninstall >/dev/null 2>&1; then
        casaos-uninstall
    else
        print_status "WARN" "Uninstaller not found, proceeding with manual cleanup..."
    fi

    print_status "INFO" "Stopping Services..."
    systemctl stop casaos.service 2>/dev/null
    systemctl disable casaos.service 2>/dev/null

    print_status "INFO" "Cleaning Files..."
    rm -rf /casaos /usr/lib/casaos /etc/casaos /var/lib/casaos /usr/bin/casaos /usr/local/bin/casaos
    
    print_status "SUCCESS" "CasaOS has been completely removed."
    pause
}

troubleshoot_casaos() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    print_status "INFO" "Service Diagnostics..."
    echo ""
    systemctl status casaos --no-pager
    echo ""
    pause
}

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "${C_WHITE} AVAILABLE ACTIONS:${C_RESET}"
    echo -e " ${C_GREEN}[1]${C_RESET} Install CasaOS         ${C_PURPLE}[3]${C_RESET} Service Status"
    echo -e " ${C_RED}[2]${C_RESET} Uninstall CasaOS       ${C_GRAY}[0]${C_RESET} Exit"
    echo ""
    
    read -p "$(print_status "INPUT" "Select Option: ")" option
    
    case $option in
        1) install_casaos ;;
        2) uninstall_casaos ;;
        3) troubleshoot_casaos ;;
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
