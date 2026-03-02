#!/bin/bash

# Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
MAGENTA="\e[35m"
RESET="\e[0m"

line() {
    echo -e "${MAGENTA}==============================================${RESET}"
}

# ===== UNINSTALL SUB-MENU =====
uninstall_menu() {
    while true; do
        clear
        line
        echo -e "${CYAN}                UNINSTALL MENU               ${RESET}"
        line
        echo -e "${YELLOW}1)${RESET} Remove Nebula"
        echo -e "${YELLOW}2)${RESET} Remove Euphoria"
        echo -e "${YELLOW}3)${RESET} Remove Add Tool Package"
        echo -e "${YELLOW}0)${RESET} Back"
        line
        read -p "Choose an option: " uopt

        case "$uopt" in
            1)
                echo -e "${RED}🧹 Removing Nebula…${RESET}"
                cd /var/www/pterodactyl || { echo -e "${RED}Path not found!${RESET}"; sleep 2; continue; }
                blueprint -r nebula
                echo -e "${GREEN}✨ Nebula removed!${RESET}"
                sleep 2
            ;;
            2)
                echo -e "${RED}🧹 Removing Euphoria…${RESET}"
                cd /var/www/pterodactyl || { echo -e "${RED}Path not found!${RESET}"; sleep 2; continue; }
                blueprint -r euphoriatheme
                echo -e "${GREEN}✨ Euphoria removed!${RESET}"
                sleep 2
            ;;
            3)
                echo -e "${RED}🧹 Removing Add Tool package…${RESET}"
                cd /var/www/pterodactyl || { echo -e "${RED}Path not found!${RESET}"; sleep 2; continue; }
                blueprint -r versionchanger
                blueprint -r mcplugins
                blueprint -r sagaminecraftplayermanager
                echo -e "${GREEN}✨ Add Tool package removed!${RESET}"
                sleep 2
            ;;
            0)
                break
            ;;
            *)
                echo -e "${RED}Galat option… try again.${RESET}"
                sleep 1
            ;;
        esac
    done
}

# ===== MAIN MENU =====
while true; do
    clear
    line
    echo -e "${CYAN}                  MAIN MENU                  ${RESET}"
    line
    echo -e "${YELLOW}1)${RESET} Nebula ${CYAN}(Auto Install)${RESET}"
    echo -e "${YELLOW}2)${RESET} Euphoria ${CYAN}(Auto Install)${RESET}"
    echo -e "${YELLOW}3)${RESET} Uninstall"
    echo -e "${YELLOW}4)${RESET} Add Tool ${CYAN}(Auto Install)${RESET}"
    echo -e "${YELLOW}0)${RESET} Exit"
    line
    read -p "Choose an option: " opt

    case "$opt" in

        # ===== NEBULA INSTALL (AUTO-ENTER ADDED) =====
        1)
            echo -e "${GREEN}✨ Nebula auto-install starting…${RESET}"
            cd /var/www/pterodactyl || { echo -e "${RED}Path not found!${RESET}"; sleep 2; continue; }

            wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/nebula.blueprint

            # AUTO ENTER + AUTO YES
            yes "" | blueprint -i nebula

            rm -f nebula.blueprint

            echo -e "${GREEN}🚀 Nebula installed!${RESET}"
            sleep 2
        ;;

        # ===== EUPHORIA INSTALL (UNCHANGED) =====
        2)
            echo -e "${GREEN}🌈 Euphoria auto-install starting…${RESET}"
            cd /var/www/pterodactyl || { echo -e "${RED}Path not found!${RESET}"; sleep 2; continue; }

            wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/euphoriatheme.blueprint
            blueprint -i euphoriatheme
            rm -f euphoriatheme.blueprint

            echo -e "${GREEN}🌟 Euphoria installed!${RESET}"
            sleep 2
        ;;

        # ===== UNINSTALL MENU NORMAL =====
        3)
            uninstall_menu
        ;;

        # ===== ADD TOOL INSTALL (UNCHANGED) =====
        4)
            echo -e "${GREEN}🛠 Add Tool auto-install starting…${RESET}"
            cd /var/www/pterodactyl || { echo -e "${RED}Path not found!${RESET}"; sleep 2; continue; }

            wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/versionchanger.blueprint
            wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/mcplugins.blueprint
            wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/sagaminecraftplayermanager.blueprint
            wget -q https://github.com/nobita329/The-Coding-Hub/raw/refs/heads/main/srv/thame/huxregister.blueprint
            blueprint -i versionchanger
            blueprint -i mcplugins
            blueprint -i sagaminecraftplayermanager
            blueprint -i huxregister.blueprint
            rm -f versionchanger.blueprint mcplugins.blueprint sagaminecraftplayermanager.blueprint huxregister.blueprint

            echo -e "${GREEN}🧩 Add Tool package installed!${RESET}"
            sleep 2
        ;;

        # ===== EXIT =====
        0)
            echo -e "${CYAN}Goodbye, legend… 🚀${RESET}"
            exit 0
        ;;

        *)
            echo -e "${RED}Galat option… try again.${RESET}"
            sleep 1
        ;;
    esac
done
