#!/bin/bash

# --- Color Theme ---
B_CYAN='\033[1;36m'
B_GREEN='\033[1;32m'
B_RED='\033[1;31m'
B_YELLOW='\033[1;33m'
B_MAGENTA='\033[1;35m'
NC='\033[0m'

# --- Docker Status Detection ---
get_docker_status() {
    container_name=$1
    if [ "$(docker ps -a -f name=^/${container_name}$ --format '{{.Names}}')" != "${container_name}" ]; then
        echo -e "${B_RED}[ NOT INSTALLED ]${NC}"
    elif [ "$(docker ps -f name=^/${container_name}$ --format '{{.Names}}')" == "${container_name}" ]; then
        echo -e "${B_GREEN}[ RUNNING ]${NC}"
    else
        echo -e "${B_YELLOW}[ STOPPED ]${NC}"
    fi
}

# --- Execution Logic (Har Baar Run Hoga) ---
execute_script() {
    local url=$1
    local c_name=$2
    local status=$(get_docker_status "$c_name")

    # Agar STOPPED hai toh pehle start karega
    if [[ "$status" == *'STOPPED'* ]]; then
        echo -e "${B_GREEN}Starting container: $c_name...${NC}"
        docker start "$c_name"
        sleep 1
    fi

    # Command hamesha run hogi, chahe status kuch bhi ho
    echo -e "${B_CYAN}Running Script for $c_name...${NC}"
    bash <(curl -s "$url")
    
    echo -e "${B_GREEN}Done! Returning to menu...${NC}"
    sleep 2
}

# --- Main Dashboard ---
while true; do
    clear
    echo -e "${B_CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
    echo -e "${B_CYAN}┃${NC}  ${B_GREEN}🚀 NOBITA CONTROL CENTER v10.0${NC}         ${B_CYAN}┃${NC}"
    echo -e "${B_CYAN}┣━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┫${NC}"
    echo -e "${B_CYAN}┃${NC} [1] Cockpit    ➔ $(get_docker_status "cockpit")"
    echo -e "${B_CYAN}┃${NC} [2] SSH WAB    ➔ $(get_docker_status "shellngn")"
    echo -e "${B_CYAN}┃${NC} [3] Kali RDP   ➔ $(get_docker_status "kali-rdp")"
    echo -e "${B_CYAN}┃${NC} [4] Win 2016   ➔ $(get_docker_status "windows2016")"
    echo -e "${B_CYAN}┃${NC} [5] Tailscale  ➔ $(get_docker_status "tailscale")"
    echo -e "${B_CYAN}┃${NC} [6] Tocaltonet ➔ $(get_docker_status "localtonet")"
    echo -e "${B_CYAN}┃${NC} [7] ${B_RED}EXIT SYSTEM${NC}"
    echo -e "${B_CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
    echo -ne "${B_YELLOW}Option select karein >> ${NC}"
    read -r choice

    case $choice in
        1) execute_script "https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/no-kvm/cockpit/run.sh" "cockpit" ;;
        2) execute_script "https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/no-kvm/SSH.sh" "shellngn" ;;
        3) execute_script "https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/no-kvm/kali-rdp.sh" "kali-rdp" ;;
        4) execute_script "https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/no-kvm/win16.sh" "windows2016" ;;
        5) execute_script "https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/no-kvm/tailscale.sh" "tailscale" ;;
        6) execute_script "https://raw.githubusercontent.com/nobita329/ptero/refs/heads/main/ptero/no-kvm/localtonet.sh" "localtonet" ;;
        7) exit 0 ;;
        *) echo -e "${B_RED}Invalid!${NC}" ; sleep 1 ;;
    esac
done
