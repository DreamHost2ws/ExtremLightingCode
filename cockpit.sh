#!/bin/bash
set -e

# ==================================================
#  COCKPIT + KVM MANAGER | DASHBOARD UI | LightPlays
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

# --- UTILS ---
pause() { echo; read -p "↩ Press Enter to return..." _; }

get_ip() { 
    curl -s --max-time 2 ifconfig.me || hostname -I | awk '{print $1}'
}

# --- STATUS CHECKERS ---
check_service() {
    if systemctl is-active --quiet "$1"; then
        echo -e "${C_GREEN}● ACTIVE${C_RESET}"
    else
        echo -e "${C_RED}● STOPPED${C_RESET}"
    fi
}

get_cockpit_port() {
    # Try to find listening port, default to 9090
    local port=$(ss -lntp 2>/dev/null | grep cockpit | awk -F: '{print $NF}' | cut -d' ' -f1 | head -n1)
    echo "${port:-9090}"
}

get_kvm_count() {
    if command -v virsh &>/dev/null && systemctl is-active --quiet libvirtd; then
        virsh list --all --count 2>/dev/null | tr -d '\n'
    else
        echo "0"
    fi
}

# --- HEADER & DASHBOARD ---
draw_header() {
    clear
    local ip=$(get_ip)
    local port=$(get_cockpit_port)
    local kvm_count=$(get_kvm_count)
    local cockpit_url="${C_WHITE}http://$ip:$port${C_RESET}"
    
    if ! systemctl is-active --quiet cockpit.socket; then
        cockpit_url="${C_GRAY}(Service Not Running)${C_RESET}"
    fi

    echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}🛠️  COCKPIT + KVM VIRTUALIZATION MANAGER v2.0${C_RESET}                        ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}HOST IP:${C_RESET} ${C_WHITE}$ip${C_RESET}                                            ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_CYAN}SERVICE STATUS:${C_RESET}                                                      ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}• Cockpit Web  :${C_RESET} $(check_service cockpit.socket)      ${C_WHITE}• URL :${C_RESET} $cockpit_url ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}• KVM/Libvirt  :${C_RESET} $(check_service libvirtd)      ${C_WHITE}• VMs :${C_RESET} ${C_YELLOW}$kvm_count${C_RESET} Detected          ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

# --- ACTIONS ---

install_stack() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_BLUE}➜ Installing Virtualization Stack...${C_RESET}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "❌ Failed to detect OS."
        exit 1
    fi

    case "$OS" in
        ubuntu)
            echo "✅ Ubuntu detected. Running ubuntu script..."
    # 1. Update
    apt update && apt upgrade -y && apt install curl wget git sudo nano -y
    # 2. Cockpit
    echo -e "${C_YELLOW}➜ Installing Cockpit (Web UI)...${C_RESET}"
    . /etc/os-release
    echo "deb http://deb.debian.org/debian ${VERSION_CODENAME}-backports main" | \
    sudo tee /etc/apt/sources.list.d/backports.list
    sudo apt update
    sudo apt install -t ${VERSION_CODENAME}-backports cockpit
    sudo systemctl enable --now cockpit.socket
    # 3. KVM / Libvirt
    echo -e "${C_YELLOW}➜ Installing KVM & Libvirt...${C_RESET}"
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
    sudo systemctl enable --now libvirtd

    # 4. Plugins & Permissions
    echo -e "${C_YELLOW}➜ Installing Cockpit-Machines Plugin...${C_RESET}"
    sudo apt install -y cockpit-machines
    
    echo -e "${C_YELLOW}➜ Configuring Permissions...${C_RESET}"
    sudo usermod -aG libvirt,kvm $USER
    # Allow root login to cockpit (optional, but often needed on VPS)
    if [ -f /etc/cockpit/disallowed-users ]; then
        sudo sed -i '/root/d' /etc/cockpit/disallowed-users
    fi
    sudo systemctl restart cockpit
            ;;
        debian)
            echo "✅ Debian detected. Running debian script..."
    # 1. Update
    apt update && apt upgrade -y && apt install curl wget git sudo nano -y
    # 2. Cockpit
    echo -e "${C_YELLOW}➜ Installing Cockpit (Web UI)...${C_RESET}"
    . /etc/os-release
    sudo apt install -t ${VERSION_CODENAME}-backports cockpit
    sudo systemctl enable --now cockpit.socket
    # 3. KVM / Libvirt
    echo -e "${C_YELLOW}➜ Installing KVM & Libvirt...${C_RESET}"
    sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virt-manager
    sudo systemctl enable --now libvirtd

    # 4. Plugins & Permissions
    echo -e "${C_YELLOW}➜ Installing Cockpit-Machines Plugin...${C_RESET}"
    sudo apt install -y cockpit-machines
    
    echo -e "${C_YELLOW}➜ Configuring Permissions...${C_RESET}"
    sudo usermod -aG libvirt,kvm $USER
    # Allow root login to cockpit (optional, but often needed on VPS)
    if [ -f /etc/cockpit/disallowed-users ]; then
        sudo sed -i '/root/d' /etc/cockpit/disallowed-users
    fi
    
    sudo systemctl restart cockpit            ;;
        *)
            echo "❌ Script works only on Ubuntu/Debian"
            exit 1
            ;;
    esac
#============================================================================================

    echo -e "${C_GREEN}✔ Installation Complete!${C_RESET}"
    pause
}

change_port() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    local current=$(get_cockpit_port)
    echo -e "Current Port: ${C_YELLOW}$current${C_RESET}"
    read -rp "Enter New Port (e.g. 8080): " NEW_PORT

    if [[ ! "$NEW_PORT" =~ ^[0-9]+$ ]]; then
        echo -e "${C_RED}Invalid Port.${C_RESET}"; pause; return
    fi

    echo -e "${C_BLUE}➜ Reconfiguring Systemd Socket...${C_RESET}"
    
    sudo mkdir -p /etc/systemd/system/cockpit.socket.d
    sudo tee /etc/systemd/system/cockpit.socket.d/listen.conf >/dev/null <<EOF
[Socket]
ListenStream=
ListenStream=$NEW_PORT
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl restart cockpit.socket

    # UFW Handling
    if command -v ufw >/dev/null; then
        echo -e "${C_YELLOW}➜ Updating Firewall...${C_RESET}"
        sudo ufw allow $NEW_PORT/tcp >/dev/null
        sudo ufw reload >/dev/null
    fi

    echo -e "${C_GREEN}✔ Port changed to $NEW_PORT${C_RESET}"
    pause
}

uninstall_stack() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_RED}⚠️  DANGER ZONE: UNINSTALL${C_RESET}"
    read -p "Remove Cockpit & KVM completely? (y/N): " confirm
    if [[ "$confirm" != "y" ]]; then return; fi

    echo -e "${C_RED}➜ Stopping Services...${C_RESET}"
    sudo systemctl disable --now cockpit.socket 2>/dev/null || true
    sudo systemctl disable --now libvirtd 2>/dev/null || true

    echo -e "${C_RED}➜ Removing Packages...${C_RESET}"
    sudo apt purge -y cockpit cockpit-machines virt-manager qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils
    sudo apt autoremove -y
    sudo apt autoclean

    echo -e "${C_GREEN}✔ Uninstalled successfully.${C_RESET}"
    pause
}

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "${C_WHITE} AVAILABLE ACTIONS:${C_RESET}"
    echo -e " ${C_GREEN}[1]${C_RESET} Install Stack (Cockpit + KVM)"
    echo -e " ${C_RED}[2]${C_RESET} Uninstall Stack"
    echo -e " ${C_YELLOW}[3]${C_RESET} Change Web Panel Port"
    echo -e " ${C_GRAY}[0]${C_RESET} Exit"
    echo ""
    
    read -rp " ➤ Select Option: " choice
    
    case "$choice" in
        1) install_stack ;;
        2) uninstall_stack ;;
        3) change_port ;;
        0) echo -e "\n${C_PURPLE}👋 Exiting...${C_RESET}"; exit 0 ;;
        *) echo -e "${C_RED}Invalid option${C_RESET}"; sleep 1 ;;
    esac
done
