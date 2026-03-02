#!/bin/bash
# ===========================================================
# LIGHTPLAYS DEV ENVIRONMENT MANAGER - TITANIUM CORE (v11.4)
# Style: Full Segmented UI / LightPlays Edition / Multi-Menu
# ===========================================================

# --- 0. PRE-INITIALIZATION ---
# Hostname change
hostnamectl set-hostname LightPlays 2>/dev/null

# --- COLORS & STYLES ---
B_BLUE='\033[1;38;5;33m'
B_CYAN='\033[1;38;5;51m'
B_PURPLE='\033[1;38;5;141m'
B_GREEN='\033[1;38;5;82m'
B_RED='\033[1;38;5;196m'
GOLD='\033[38;5;220m'
W='\033[1;38;5;255m'
G='\033[0;38;5;244m'
BG_SHADE='\033[48;5;236m' 
NC='\033[0m'

# --- UTILS ---
pause() { echo; echo -ne "  ${G}➜${NC} ${W}Press Enter to return...${NC}"; read _; }

# --- DATA AGGREGATOR ---
get_metrics() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", $2+$4}')
    RAM=$(free | grep Mem | awk '{printf "%.0f", $3*100/$2}')
    UPT=$(uptime -p | sed 's/up //')
    DISK=$(df -h / | awk 'NR==2 {print $5}')
    CURRENT_HOST=$(hostname)
    
    KVM_STATUS="${B_RED}OFF${NC}"
    if [ -e /dev/kvm ]; then KVM_STATUS="${B_GREEN}ON${NC}"; fi
}

# --- SUB-MENU: PANEL CONTROL ---
panel_menu() {
    while true; do
        clear
        get_metrics

        echo -e " ${B_BLUE}${NC}${BG_SHADE}${W}   HOST: $CURRENT_HOST ${NC}${B_BLUE}${NC}  ${B_PURPLE}${NC}${BG_SHADE}${W}   $UPT ${NC}${B_PURPLE}${NC}"
        echo -e ""
        echo -e "  ${GOLD}██╗     ██╗ ██████╗ ██╗  ██╗████████╗██████╗ ██╗      █████╗ ██╗   ██╗${NC}"
        echo -e "  ${GOLD}██║     ██║██╔════╝ ██║  ██║╚══██╔══╝██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝${NC}"
        echo -e "  ${GOLD}██║     ██║██║  ███╗███████║   ██║   ██████╔╝██║     ███████║ ╚████╔╝ ${NC}"
        echo -e "  ${GOLD}██║     ██║██║   ██║██╔══██║   ██║   ██╔═══╝ ██║     ██╔══██║  ╚██╔╝  ${NC}"
        echo -e "  ${GOLD}███████╗██║╚██████╔╝██║  ██║   ██║   ██║     ███████╗██║  ██║   ██║   ${NC}"
        echo -e "  ${G}──────────────────────────────────────────${NC}"

        echo -e "  ${W}LightPlays Control Panels:${NC}\n"
        echo -e "  ${B_CYAN}  WEB INTERFACES${NC}"
        echo -e "  ${G}├─ ${W}[1]${NC} Install Cockpit ${G}(Web VM Manager)${NC}"
        echo -e "  ${G}├─ ${W}[2]${NC} Install CasaOS  ${G}(Home Cloud UI)${NC}"
        echo -e "  ${G}└─ ${W}[3]${NC} Install 1Panel  ${G}(Modern Hosting)${NC}"
        echo -e ""
        echo -e "  ${B_PURPLE}  NAVIGATION${NC}"
        echo -e "  ${G}└─ ${B_BLUE}${NC}${BG_SHADE}${W} [0] BACK TO MAIN MENU ${NC}${B_BLUE}${NC}"

        echo -e "\n  ${G}──────────────────────────────────────────${NC}"
        echo -ne "  ${B_CYAN}➜${NC} ${W}Panel ID${NC} ${G}(0-3):${NC} "; read p_opt

        case $p_opt in
            1) echo -e "\n  ${B_BLUE}➜ Installing Cockpit...${NC}"
               bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/panel/cockpit.sh); pause ;;
            2) echo -e "\n  ${B_BLUE}➜ Installing CasaOS...${NC}"
               bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/panel/casaos.sh); pause ;;
            3) echo -e "\n  ${B_BLUE}➜ Installing 1Panel...${NC}"
               bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/vps/panel/1panel.sh); pause ;;
            0) break ;;
            *) echo -e "  ${B_RED}Invalid option!${NC}"; sleep 0.7 ;;
        esac
    done
}

# --- MAIN LOOP ---
while true; do
    render_ui
    read -r opt
    case $opt in
        0) echo -e "\n  ${B_RED}Terminating LightPlays session...${NC} Goodbye, LightPlays."; exit 0 ;;
        *) ;;
    esac
done
