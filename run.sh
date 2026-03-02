#!/bin/bash
# ===========================================================
# LIGHTPLAYS DEV ENVIRONMENT MANAGER - TITANIUM CORE (v11.4)
# Style: Full Segmented UI / LightPlays Edition / Multi-Menu
# ===========================================================

# --- 0. PRE-INITIALIZATION ---
hostnamectl set-hostname LightPlays 2>/dev/null

# --- COLORS ---
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
pause() { 
    echo
    echo -ne "  ${G}➜${NC} ${W}Press Enter to continue...${NC}"
    read _
}

# --- SYSTEM METRICS ---
get_metrics() {
    CPU=$(top -bn1 | awk -F',' '/Cpu/ {printf "%.0f", $1}' | awk '{print $2}')
    RAM=$(free | awk '/Mem/ {printf "%.0f", $3*100/$2}')
    UPT=$(uptime -p | sed 's/up //')
    DISK=$(df -h / | awk 'NR==2 {print $5}')
    CURRENT_HOST=$(hostname)

    KVM_STATUS="${B_RED}OFF${NC}"
    [ -e /dev/kvm ] && KVM_STATUS="${B_GREEN}ON${NC}"
}

# --- PANEL MENU ---
panel_menu() {
    while true; do
        clear
        get_metrics

        echo -e " ${B_BLUE}${NC}${BG_SHADE}${W} HOST: $CURRENT_HOST ${NC}${B_BLUE}${NC}  ${B_PURPLE}${NC}${BG_SHADE}${W} UPTIME: $UPT ${NC}${B_PURPLE}${NC}"
        echo
        echo -e "  ${GOLD}LightPlays Panel Control Center${NC}"
        echo -e "  ${G}──────────────────────────────────────────${NC}"
        echo
        echo -e "  ${W}[1]${NC} Install Cockpit"
        echo -e "  ${W}[2]${NC} Install CasaOS"
        echo -e "  ${W}[3]${NC} Install 1Panel"
        echo
        echo -e "  ${W}[0]${NC} Back"
        echo
        echo -ne "  ${B_CYAN}➜ Select Option:${NC} "
        read p_opt

        case $p_opt in
            1) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/main/ptero/vps/panel/cockpit.sh); pause ;;
            2) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/main/ptero/vps/panel/casaos.sh); pause ;;
            3) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/main/ptero/vps/panel/1panel.sh); pause ;;
            0) break ;;
            *) echo -e "${B_RED}Invalid option.${NC}"; sleep 1 ;;
        esac
    done
}

# --- MAIN UI ---
render_ui() {
    clear
    get_metrics

    echo -e " ${B_BLUE}${NC}${BG_SHADE}${W} HOST: $CURRENT_HOST ${NC}${B_BLUE}${NC}  ${B_GREEN}${NC}${BG_SHADE}${W} KVM: $KVM_STATUS ${NC}${B_GREEN}${NC}"
    echo
    echo -e "${B_CYAN}  ██╗     ██╗ ██████╗ ██╗  ██╗████████╗██████╗ ██╗      █████╗ ██╗   ██╗${NC}"
    echo -e "${B_PURPLE}  ██║     ██║██╔════╝ ██║  ██║╚══██╔══╝██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝${NC}"
    echo -e "${GOLD}  ██║     ██║██║  ███╗███████║   ██║   ██████╔╝██║     ███████║ ╚████╔╝ ${NC}"
    echo -e "${GOLD}  ██║     ██║██║   ██║██╔══██║   ██║   ██╔═══╝ ██║     ██╔══██║  ╚██╔╝  ${NC}"
    echo -e "${B_GREEN}  ███████╗██║╚██████╔╝██║  ██║   ██║   ██║     ███████╗██║  ██║   ██║   ${NC}"
    echo
    echo -e "  ${G}CPU:${NC} ${CPU}%   ${G}RAM:${NC} ${RAM}%   ${G}Disk:${NC} ${DISK}"
    echo
    echo -e "  ${W}[1]${NC} Panel Control Center"
    echo -e "  ${W}[0]${NC} Exit"
    echo
    echo -ne "  ${B_CYAN}➜ Command:${NC} "
}

# --- MAIN LOOP ---
while true; do
    render_ui
    read opt
    case $opt in
        1) panel_menu ;;
        0) echo -e "\n${B_RED}Terminating LightPlays session...${NC}"; exit 0 ;;
        *) echo -e "${B_RED}Invalid input.${NC}"; sleep 1 ;;
    esac
done
