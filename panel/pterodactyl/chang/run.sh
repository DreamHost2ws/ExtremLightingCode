#!/bin/bash

# ==========================================
# 🎨 UI CONFIGURATION & COLORS
# ==========================================
# Regular Colors
R="\e[31m"; G="\e[32m"; Y="\e[33m"
B="\e[34m"; M="\e[35m"; C="\e[36m"
W="\e[97m"; N="\e[0m"

# Bold & Effects
BR="\e[1;31m"; BG="\e[1;32m"; BY="\e[1;33m"
BB="\e[1;34m"; BM="\e[1;35m"; BC="\e[1;36m"
BW="\e[1;97m"
UL="\e[4m"
BLINK="\e[5m"

# Backgrounds
BG_BLUE="\e[44m"
BG_RED="\e[41m"

# ==========================================
# 🛠️ HELPER FUNCTIONS
# ==========================================

# Trap Ctrl+C
trap 'echo -e "\n${R} [!] Force exit detected.${N}"; exit 1' SIGINT

# Centered Text function
print_center() {
    local text="$1"
    local width=60
    local padding=$(( (width - ${#text}) / 2 ))
    printf "%*s%s%*s\n" $padding "" "$text" $padding ""
}

# The Header
header() {
  clear
  echo -e "${BC}"
  echo " ╔══════════════════════════════════════════════════════════╗"
  echo " ║                                                          ║"
  printf " ║${BW}%-58s${BC}║\n" "$(print_center "⚡ BLUEPRINT CONTROL HUB ⚡")"
  echo " ║                                                          ║"
  printf " ║${B}%-58s${BC}║\n" "$(print_center "Minimal • Clean • High Performance")"
  echo " ║                                                          ║"
  echo " ╚══════════════════════════════════════════════════════════╝"
  echo -e "${N}"
  
  # System Info (Optional visual touch)
  echo -e " ${B}User:${N} $(whoami)  ${B}Host:${N} $(hostname)  ${B}Date:${N} $(date +'%H:%M')"
  echo -e "${C} ──────────────────────────────────────────────────────────${N}"
}

# Pause with style
pause() {
  echo
  echo -e "${B} ──────────────────────────────────────────────────────────${N}"
  read -rp " ↩️  Press Enter to return to main menu..."
}

# ==========================================
# 📋 ACTIONS
# ==========================================

blueprint1() {
  header
  echo -e "\n${BG} [ ACTION STARTED ] ${N} ${W}Running Blueprint 1...${N}\n"
  bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/thame/blueprint.sh)
  pause
}

blueprint2() {
  header
  echo -e "\n${BY} [ ACTION STARTED ] ${N} ${W}Running Blueprint 2 (Rebuild)...${N}\n"
  bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/thame/blueprint-2.sh)
  pause
}

autofix() {
    header
    echo -e "\n${BM} [ DIAGNOSTICS ] ${N} ${W}Attempting Auto-Fix...${N}\n"
    bash <(curl -s https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/thame/fix.sh)
    pause
}

# ==========================================
# 🖥️ MAIN MENU
# ==========================================
show_menu() {
  header
  echo -e "${BW} SELECT AN OPTION:${N}\n"

  echo -e "  ${BG}[ 1 ]${N}  🚀  Install Blueprint 1"
  echo -e "  ${BY}[ 2 ]${N}  ⚡  Install Blueprint 2 (Fresh Rebuild)"
  echo -e "  ${BM}[ 3 ]${N}  🛠️   Auto Fix / Repair"
  echo -e "  ${BM}[ 4 ]${N}  🛠️   hyperv1"
  echo -e ""
  echo -e "  ${BR}[ 0 ]${N}  ❌  Exit Panel"
  
  echo -e "\n${C} ──────────────────────────────────────────────────────────${N}"
}

# ==========================================
# 🔄 EXECUTION LOOP
# ==========================================
while true; do
  show_menu
  read -p " 👉 Enter your choice: " opt

  case $opt in
    1) blueprint1 ;;
    2) blueprint2 ;;
    3) autofix ;;
    4) bash <(curl -s https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/thame/hyperv1.sh) ;;
    0) 
       echo -e "\n${M} 👋 Exiting... Panel shant ho gaya.${N}"
       sleep 0.5
       clear
       exit 
       ;;
    *) 
       echo -e "\n${R} ❌ Invalid Option! Please try again.${N}"
       sleep 1
       ;;
  esac
done
