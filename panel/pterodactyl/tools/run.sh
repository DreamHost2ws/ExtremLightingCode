#!/bin/bash

# ==================================================
#  SERVER UTILITY MENU | v2.0
# ==================================================

# --- COLORS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
GRAY='\033[1;30m'
NC='\033[0m' # No Color

# --- HELPER FUNCTIONS ---
pause() {
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
    echo ""
}

# ===================== TOOLS MENU =====================
tools_menu() {
    while true; do
        clear
        # -- HEADER --
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}║${NC}          ${PURPLE}⚡ SERVER UTILITIES & TOOLS ⚡${NC}                  ${CYAN}║${NC}"
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GRAY}  Host: $(hostname) | User: $(whoami)${NC}"
        echo ""

        # -- SECTION 1: NETWORK & ACCESS --
        echo -e "${BLUE}  [ ACCESS & NETWORK ]${NC}"
        echo -e "  ${GREEN}1)${NC} Root Access         ${GRAY}:: (Enable Root/Sudo)${NC}"
        echo -e "  ${GREEN}2)${NC} Tailscale           ${GRAY}:: (Mesh VPN Setup)${NC}"
        echo -e "  ${GREEN}3)${NC} Zerotier            ${GRAY}:: (wifi VPN Setup)${NC}"
        echo -e "  ${GREEN}4)${NC} Cloudflare DNS      ${GRAY}:: (Tunnel & DNS)${NC}"
        echo ""

        # -- SECTION 2: SYSTEM & OPS --
        echo -e "${YELLOW}  [ SYSTEM OPERATIONS ]${NC}"
        echo -e "  ${GREEN}5)${NC} System Info         ${GRAY}:: (Specs & Status)${NC}"
        echo -e "  ${GREEN}6)${NC} Port Forward        ${GRAY}:: (TCP/UDP)${NC}"
        echo ""

        # -- SECTION 3: INTERFACE --
        echo -e "${PURPLE}  [ GUI & TERMINAL ]${NC}"
        echo -e "  ${GREEN}7)${NC} Web Terminal        ${GRAY}:: (Browser Shell)${NC}"
        echo -e "  ${GREEN}8)${NC} RDP Installer       ${GRAY}:: (Remote Desktop)${NC}"
        echo ""

        # -- FOOTER --
        echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
        echo -e "  ${RED}8) ↩ Back / Exit${NC}"
        echo ""
        
        # -- INPUT --
        echo -ne "${CYAN}  Select Tool → ${NC}"
        read t

        case $t in
            1) 
                echo -e "\n${YELLOW}Running Root Access Script...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/root.sh) 
                pause ;;
            2) 
                echo -e "\n${YELLOW}Running Tailscale Installer...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/tailscale.sh) 
                pause ;;
            3) 
                echo -e "\n${YELLOW}Running Zerotier Installer...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/zerotier.sh) 
                pause ;;
            4) 
                echo -e "\n${YELLOW}Running Cloudflare Script...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/cloudflare.sh) 
                pause ;;
            5) 
                echo -e "\n${YELLOW}Fetching System Info...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/info.sh) 
                pause ;;
            6) 
                echo -e "\n${YELLOW}Running tcp Optimizer...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/localtonet.sh) 
                pause ;;
            7) 
                echo -e "\n${YELLOW}Installing Web Terminal...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/tools/terminal.sh) 
                pause ;;
            8) 
                echo -e "\n${YELLOW}Installing RDP...${NC}"
                bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/tools/rdp.sh) 
                pause ;;
            0) 
                break ;;
            *) 
                echo -e "${RED}Invalid Option${NC}"
                sleep 1 ;;
        esac
    done
}

# --- EXECUTE ---
tools_menu
