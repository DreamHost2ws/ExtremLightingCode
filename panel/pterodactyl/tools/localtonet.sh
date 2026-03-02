#!/bin/bash

# --- COLORS ---
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- UI HEADER ---
clear
echo -e "${CYAN}==================================================${NC}"
echo -e "${BOLD}${MAGENTA}          LOCALTONET AUTO-RUN PRO              ${NC}"
echo -e "${CYAN}==================================================${NC}"

# 1. Install Check with UI
echo -e "${BLUE}[*] Checking system requirements...${NC}"
if ! command -v localtonet &> /dev/null; then
    echo -e "${YELLOW}[!] Localtonet not found. Installing...${NC}"
    curl -fsSL https://localtonet.com/install.sh | sh
    echo -e "${GREEN}[✓] Installation Complete!${NC}"
else
    echo -e "${GREEN}[✓] Localtonet is already installed.${NC}"
fi

echo -e "${CYAN}--------------------------------------------------${NC}"

# 2. Token Input with Color
echo -e "${BOLD}${YELLOW}👉 Please enter your Auth-Token:${NC}"
echo -en "${CYAN}Token > ${NC}"
read USER_TOKEN

# Validation
if [ -z "$USER_TOKEN" ]; then
    echo -e "${RED}✘ Error: Token missing! Exiting...${NC}"
    exit 1
fi

# 3. Setting Token
echo -e "${BLUE}[*] Applying Authentication...${NC}"
localtonet authtoken "$USER_TOKEN"
echo -e "${GREEN}[✓] Token Saved Successfully!${NC}"

echo -e "${CYAN}--------------------------------------------------${NC}"

# 5. Final Launch
echo -e "${MAGENTA}🚀 Launching Tunnel on Port ${PORT}...${NC}"
echo -e "${BLUE}Press CTRL+C to stop the tunnel.${NC}"
echo -e "${CYAN}==================================================${NC}"
