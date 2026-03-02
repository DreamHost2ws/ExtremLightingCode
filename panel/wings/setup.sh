#!/bin/bash

# ==========================================
#  PTERO AUTO MENU - ENHANCED UI VERSION
# ==========================================

# --- Colors & Formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- 1. Check for Root ---
# This ensures the user has permission to edit system files
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}${BOLD}Error: This script must be run as root!${NC}" 
   exit 1
fi

# --- 2. Header Function ---
draw_header() {
    clear
    echo -e "${CYAN}${BOLD}==================================================${NC}"
    echo -e "${CYAN}           PTERODACTYL WINGS AUTO-MENU            ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo ""
}

# --- 3. Main Logic Loop ---
while true; do
    draw_header
    echo -e "${BOLD}Select an operation:${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} Auto-Setup ${YELLOW}(Install Config & Manager)${NC}"
    echo -e "  ${GREEN}[2]${NC} Auto-Deploy ${YELLOW}(Reset Config & Deploy Token)${NC}"
    echo -e "  ${RED}[0]${NC} Exit"
    echo ""
    echo -e "${CYAN}==================================================${NC}"
    echo -n "Enter option [0-2]: "
    read opt

    case $opt in
        1)
            echo ""
            echo -e "${GREEN}>> Running Auto-Setup...${NC}"
            sleep 1
            
            # Run Config Script
            bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/wings/config.sh)
            
            # Run Manager Script
            bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/wings/Manag)
            
            echo ""
            echo -e "${GREEN}>> Setup Complete! Press Enter to return to menu.${NC}"
            read
            ;;
        2)
            echo ""
            echo -e "${GREEN}>> Starting Auto-Deploy...${NC}"
            
            # Warning about config deletion
            echo -e "${RED}!! This will delete /etc/pterodactyl/config.yml !!${NC}"
            rm -f /etc/pterodactyl/config.yml
            
            echo ""
            echo -e "${YELLOW}Paste your Auto-Deploy Command (starts with 'sudo wings...'):${NC}"
            read CMD

            # Verify command is not empty
            if [ -z "$CMD" ]; then
                echo -e "${RED}Error: No command entered.${NC}"
            else
                echo -e "${GREEN}>> Executing deployment...${NC}"
                eval "$CMD"
                
                echo -e "${GREEN}>> Restarting Wings...${NC}"
                systemctl restart wings
                
                echo -e "${GREEN}>> Fetching Manager...${NC}"
                bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/wings/Manag)
            fi
            
            echo ""
            echo -e "${GREEN}>> Deploy process finished. Press Enter to return.${NC}"
            read
            ;;
        0)
            echo ""
            echo -e "${RED}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo ""
            echo -e "${RED}Invalid option! Press Enter to try again.${NC}"
            read
            ;;
    esac
done
