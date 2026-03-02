#!/bin/bash

# ===============================
# 🎨 THEME CONFIG (BLUEPRINT)
# ===============================
BLUE="\e[34m"
CYAN="\e[36m"
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
MAGENTA="\e[35m"
WHITE="\e[97m"
RESET="\e[0m"
BOLD="\e[1m"

clear

# ===============================
# 🧠 HEADER BANNER
# ===============================
banner() {
clear
echo -e "${BLUE}${BOLD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "     🚀 BLUEPRINT CONTROL PANEL LP"
echo "     🎨 Theme UI • Modern • Fast"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${RESET}"
}

# ===============================
# 📋 MAIN MENU
# ===============================
menu() {
banner
echo -e "${CYAN}[1]${WHITE} Blueprint Tools"
echo -e "${CYAN}[2]${WHITE} Theme Manager"
echo -e "${CYAN}[3]${WHITE} Exit"
echo
read -p "➜ Select Option: " opt

case $opt in
1) bash <(curl -fsSL https://raw.githubusercontent.com/DreamHost2ws/ExtremLightingCode/main/panel/pterodactyl/chang/run.sh) ;;
2) bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/thame/chang/run.sh) ;;
3) exit ;;
*) echo -e "${RED}Invalid Option${RESET}" ; sleep 1 ; menu ;;
esac
}

menu
