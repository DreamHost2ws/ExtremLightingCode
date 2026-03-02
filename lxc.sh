#!/bin/bash

# ==================================================
#  LXC/LXD CONTAINER MANAGER | DASHBOARD UI
# ==================================================

# --- COLORS & STYLES ---
R="\e[31m"; G="\e[32m"; Y="\e[33m"; B="\e[34m"; C="\e[36m"; M="\e[35m"; W="\e[37m"; N="\e[0m"
BOLD="\e[1m"

# --- INIT CHECKS ---
if [ "$EUID" -ne 0 ]; then
    # Check if user is in lxd group instead of forcing root
    if ! groups | grep -q "lxd"; then
        echo -e "${R}❌ Error: Please run as root or ensure you are in the 'lxd' group.${N}"
        exit 1
    fi
fi

# --- UTILS ---
pause() { echo; read -p "↩ Press Enter to return..." _; }

# --- STATUS CHECKERS ---
get_lxd_status() {
    if systemctl is-active --quiet snap.lxd.daemon || systemctl is-active --quiet lxd; then
        echo -e "${G}ACTIVE${N}"
    else
        echo -e "${R}INACTIVE${N}"
    fi
}

count_containers() {
    lxc list --format csv 2>/dev/null | wc -l
}

count_images() {
    lxc image list --format csv 2>/dev/null | wc -l
}

# --- HEADER & DASHBOARD ---
draw_header() {
    clear
    local lxd_stat=$(get_lxd_status)
    local cont_count=$(count_containers)
    local img_count=$(count_images)
    
    echo -e "${C}╔══════════════════════════════════════════════════════════════╗${N}"
    echo -e "${C}║${W}${BOLD}              📦 LXC/LXD CONTAINER MANAGER v3.0               ${C}║${N}"
    echo -e "${C}╠══════════════════════════════════════════════════════════════╣${N}"
    echo -e "${C}║${M} SYSTEM STATUS:                                               ${C}║${N}"
    echo -e "${C}║${W} • LXD Service :${N} $lxd_stat          ${W}• Containers :${N} ${G}$cont_count${N}             ${C}║${N}"
    echo -e "${C}║${W} • Storage     :${N} $(df -h /var/lib/lxd 2>/dev/null | awk 'NR==2 {print $4}' || echo "N/A") free         ${W}• Images     :${N} ${Y}$img_count${N}             ${C}║${N}"
    echo -e "${C}╚══════════════════════════════════════════════════════════════╝${N}"
    echo
}

# --- CORE FUNCTIONS ---

create_container() {
    echo -e "${C}┌──────────────────────────────────────────────┐${N}"
    echo -e "${C}│ 🚀 CREATE NEW CONTAINER                      │${N}"
    echo -e "${C}└──────────────────────────────────────────────┘${N}"
    
    # 1. Select Image
    echo -e "${Y}Available Images:${N}"
    echo "1) Ubuntu 22.04 (Jammy)"
    echo "2) Ubuntu 20.04 (Focal)"
    echo "3) Debian 12 (Bookworm)"
    echo "4) Debian 11 (Bullseye)"
    echo "5) Alpine Linux (Edge)"
    echo "6) CentOS 9 Stream"
    echo "7) Custom Image Name"
    echo
    read -p "Select Image [1-7]: " img_opt
    
    case $img_opt in
        1) IMG="ubuntu:22.04" ;;
        2) IMG="ubuntu:20.04" ;;
        3) IMG="images:debian/12" ;;
        4) IMG="images:debian/11" ;;
        5) IMG="images:alpine/edge" ;;
        6) IMG="images:centos/9-Stream" ;;
        7) read -p "Enter Image Name (e.g., ubuntu:18.04): " IMG ;;
        *) echo -e "${R}Invalid option.${N}"; pause; return ;;
    esac

    # 2. Config
    echo
    read -p "🏷️  Container Name: " NAME
    if [[ -z "$NAME" ]]; then echo -e "${R}Name required.${N}"; pause; return; fi
    
    read -p "🧠 Memory Limit (e.g., 512MB, 1GB, leave empty for none): " MEM
    read -p "⚡ CPU Limit (e.g., 1, 2, leave empty for none): " CPU
    
    # 3. Launch
    echo -e "\n${G}▶ Launching $NAME using $IMG...${N}"
    lxc launch "$IMG" "$NAME"
    
    # 4. Limits
    if [[ -n "$MEM" ]]; then
        lxc config set "$NAME" limits.memory "$MEM"
        echo -e "${G}✔ Memory limited to $MEM${N}"
    fi
    if [[ -n "$CPU" ]]; then
        lxc config set "$NAME" limits.cpu "$CPU"
        echo -e "${G}✔ CPU limited to $CPU cores${N}"
    fi
    
    echo -e "${G}✅ Container Created Successfully!${N}"
    pause
}

list_containers() {
    echo -e "${C}┌──────────────────────────────────────────────┐${N}"
    echo -e "${C}│ 📋 ACTIVE CONTAINERS                         │${N}"
    echo -e "${C}└──────────────────────────────────────────────┘${N}"
    lxc list
    pause
}

manage_container() {
    echo -e "${Y}Select a Container to Manage:${N}"
    lxc list -c n --format csv | nl -w2 -s') '
    echo
    read -p "Enter Name: " NAME
    
    if ! lxc info "$NAME" &>/dev/null; then
        echo -e "${R}Container not found.${N}"
        pause; return
    fi
    
    while true; do
        clear
        echo -e "${C}⚙️  MANAGING: ${W}$NAME${N}"
        echo "----------------------------------------"
        echo -e "Status: $(lxc list "$NAME" -c s --format csv)"
        echo -e "IP:     $(lxc list "$NAME" -c 4 --format csv | awk '{print $1}')"
        echo "----------------------------------------"
        echo -e "1) ▶ Start       4) 🐚 Shell Access"
        echo -e "2) ⏹ Stop        5) 🗑️  Delete"
        echo -e "3) 🔄 Restart     6) 🔙 Back"
        echo
        read -p "Action: " act
        
        case $act in
            1) lxc start "$NAME"; echo "Started." ;;
            2) lxc stop "$NAME"; echo "Stopped." ;;
            3) lxc restart "$NAME"; echo "Restarted." ;;
            4) lxc exec "$NAME" -- bash || lxc exec "$NAME" -- sh ;;
            5) 
                read -p "Are you sure? (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    lxc delete "$NAME" --force
                    echo "Deleted."
                    pause; return
                fi
                ;;
            6) return ;;
        esac
        sleep 1
    done
}

install_lxd() {
    echo -e "${Y}📦 Installing LXD/LXC...${N}"
    if command -v apt &>/dev/null; then
        apt update
        apt install -y snapd
        snap install lxd
        lxd init --auto
        adduser "$SUDO_USER" lxd
        echo -e "${G}✅ Installed. Please logout and login again.${N}"
    else
        echo -e "${R}Unsupported OS for auto-install.${N}"
    fi
    pause
}

system_info() {
    echo -e "${C}📊 SYSTEM RESOURCES${N}"
    lxc info
    pause
}

snapshot_manager() {
    echo -e "${Y}Select Container for Snapshot:${N}"
    read -p "Name: " NAME
    
    echo -e "1) Create Snapshot"
    echo -e "2) Restore Snapshot"
    read -p "Choice: " ch
    
    if [[ "$ch" == "1" ]]; then
        read -p "Snapshot Name: " snap
        lxc snapshot "$NAME" "$snap"
        echo "Created."
    elif [[ "$ch" == "2" ]]; then
        lxc info "$NAME" | grep "Snapshots:" -A 10
        read -p "Restore which snapshot? " snap
        lxc restore "$NAME" "$snap"
        echo "Restored."
    fi
    pause
}

# --- MAIN MENU ---
while true; do
    draw_header
    
    echo -e "${W} CONTAINER ACTIONS:${N}"
    echo -e " ${G}[1]${N} Create Container       ${B}[4]${N} List All"
    echo -e " ${Y}[2]${N} Manage Container       ${M}[5]${N} Snapshots"
    echo -e " ${R}[3]${N} Delete Container       ${C}[6]${N} System Info"
    echo
    echo -e "${W} SYSTEM ACTIONS:${N}"
    echo -e " ${B}[7]${N} Install LXD            ${W}[0]${N} Exit"
    echo
    read -p " ➤ Select Option: " opt
    
    case $opt in
        1) create_container ;;
        2) manage_container ;;
        3) 
            read -p "Container Name: " del_name
            lxc delete "$del_name" --force
            echo "Deleted."
            pause 
            ;;
        4) list_containers ;;
        5) snapshot_manager ;;
        6) system_info ;;
        7) install_lxd ;;
        0) echo -e "${G}Goodbye!${N}"; exit 0 ;;
        *) echo -e "${R}Invalid Option${N}"; sleep 1 ;;
    esac
done
