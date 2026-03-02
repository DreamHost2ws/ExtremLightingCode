#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# ==================================================
#  MULTI-OS VM TOOLS INSTALLER | LightPlays
# ==================================================

# --- COLORS & STYLES ---
C_RESET='\033[0m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'
BOLD='\033[1m'

# --- UI FUNCTIONS ---

draw_header() {
    clear
    echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}${BOLD}       🛠️  MULTI-OS VM TOOLS INSTALLER v2.0           ${C_RESET} ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}System:${C_RESET} Auto-Detect                                        ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}Target:${C_RESET} QEMU/KVM & Cloud Utils                             ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

print_info() { echo -e " ${C_BLUE}➜${C_RESET} ${C_WHITE}$1${C_RESET}"; }
print_success() { echo -e " ${C_GREEN}✔${C_RESET} ${C_GREEN}$1${C_RESET}"; }
print_error() { echo -e " ${C_RED}✖${C_RESET} ${C_RED}$1${C_RESET}"; }
print_warn() { echo -e " ${C_YELLOW}⚠${C_RESET} ${C_YELLOW}$1${C_RESET}"; }

# Loading Spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    echo -ne " ${C_CYAN}⚙️  Processing...${C_RESET} "
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "[%c]" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "   \b\b\b"
}

# --- CORE UTILS ---
cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

# --- 1. DETECT OS ---
detect_os() {
    print_info "Detecting Operating System..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=${VERSION_ID%%.*}
        print_success "Detected: ${C_CYAN}${PRETTY_NAME}${C_RESET}"
    else
        print_error "Cannot detect OS structure."
        exit 1
    fi
    echo ""
}

# --- 2. INSTALL PACKAGES ---
install_packages() {
    INSTALL=()
    print_info "Checking required dependencies..."

    # Define packages based on OS
    case "$OS" in
        ubuntu|debian|kali|linuxmint)
            cmd_exists qemu-system-x86_64 || INSTALL+=(qemu-kvm qemu-utils)
            cmd_exists wget || INSTALL+=(wget)
            cmd_exists lsof || INSTALL+=(lsof)
            cmd_exists growpart || INSTALL+=(cloud-guest-utils)
            cmd_exists cloud-localds || INSTALL+=(cloud-image-utils)
            cmd_exists genisoimage || INSTALL+=(genisoimage)
            
            INSTALL_CMD="sudo apt update -y && sudo apt install -y ${INSTALL[*]}"
            ;;

        fedora)
            cmd_exists qemu-system-x86_64 || INSTALL+=(qemu-kvm qemu-img)
            cmd_exists wget || INSTALL+=(wget)
            cmd_exists lsof || INSTALL+=(lsof)
            cmd_exists growpart || INSTALL+=(cloud-utils-growpart)
            cmd_exists genisoimage || INSTALL+=(genisoimage)
            
            INSTALL_CMD="sudo dnf install -y epel-release && sudo dnf install -y ${INSTALL[*]} cloud-utils"
            ;;

        centos|rocky|almalinux|rhel)
            cmd_exists qemu-system-x86_64 || INSTALL+=(qemu-kvm qemu-img)
            cmd_exists wget || INSTALL+=(wget)
            cmd_exists lsof || INSTALL+=(lsof)
            cmd_exists growpart || INSTALL+=(cloud-utils-growpart)
            cmd_exists genisoimage || INSTALL+=(genisoimage)
            
            # EPEL Logic
            PRE_CMD=""
            if ! rpm -q epel-release >/dev/null 2>&1; then
                PRE_CMD="sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${VERSION_ID}.noarch.rpm &&"
            fi
            INSTALL_CMD="${PRE_CMD} sudo dnf install -y ${INSTALL[*]} cloud-utils"
            ;;

        amzn) # Amazon Linux
            cmd_exists qemu-system-x86_64 || INSTALL+=(qemu-kvm qemu-img)
            cmd_exists wget || INSTALL+=(wget)
            cmd_exists lsof || INSTALL+=(lsof)
            cmd_exists growpart || INSTALL+=(cloud-utils-growpart)
            
            INSTALL_CMD="sudo dnf install -y ${INSTALL[*]} cloud-utils"
            ;;

        arch|manjaro)
            cmd_exists qemu-system-x86_64 || INSTALL+=(qemu-full)
            cmd_exists wget || INSTALL+=(wget)
            cmd_exists lsof || INSTALL+=(lsof)
            cmd_exists growpart || INSTALL+=(cloud-guest-utils)
            cmd_exists genisoimage || INSTALL+=(cdrtools)
            
            INSTALL_CMD="sudo pacman -Sy --noconfirm ${INSTALL[*]}"
            ;;

        opensuse*|sles)
            cmd_exists qemu-system-x86_64 || INSTALL+=(qemu-tools qemu-kvm)
            cmd_exists wget || INSTALL+=(wget)
            cmd_exists lsof || INSTALL+=(lsof)
            cmd_exists growpart || INSTALL+=(cloud-utils-growpart)
            cmd_exists genisoimage || INSTALL+=(genisoimage)
            
            INSTALL_CMD="sudo zypper --non-interactive install ${INSTALL[*]}"
            ;;

        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac

    # Execution Logic
    if [ ${#INSTALL[@]} -eq 0 ]; then
        print_success "All dependencies are already installed."
    else
        print_warn "Missing packages: ${C_WHITE}${INSTALL[*]}${C_RESET}"
        print_info "Installing now (this may take a moment)..."
        
        # Run install in background with spinner
        eval "$INSTALL_CMD" > /dev/null 2>&1 &
        spinner $!
        
        if [ $? -eq 0 ]; then
            echo ""
            print_success "Packages installed successfully."
        else
            echo ""
            print_error "Installation failed. Check logs or run manually."
            exit 1
        fi
    fi
    echo ""
}

# --- 3. SETUP LINKS ---
setup_links() {
    print_info "Verifying system binaries..."
    
    local linked=0
    
    # Link qemu-kvm if missing in path but present in libexec (Common in RHEL/CentOS)
    if [ -f /usr/libexec/qemu-kvm ] && ! cmd_exists qemu-system-x86_64; then
        sudo ln -sf /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64
        linked=1
    fi

    # Link cloud-localds if installed differently
    if cmd_exists cloud-localds && [ -f /usr/bin/cloud-localds ] && [ ! -f /usr/local/bin/cloud-localds ]; then
        sudo ln -sf /usr/bin/cloud-localds /usr/local/bin/cloud-localds
        linked=1
    fi

    if [ $linked -eq 1 ]; then
        print_success "Symlinks updated for compatibility."
    else
        print_success "Binary paths are correct."
    fi
}

# --- MAIN ---
main() {
    draw_header
    detect_os
    install_packages
    setup_links
    
    echo ""
    echo -e "${C_BLUE}══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "   ${C_GREEN}✅ SETUP COMPLETE${C_RESET} | Ready to run VM scripts"
    echo -e "${C_BLUE}══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
}

main "$@"
