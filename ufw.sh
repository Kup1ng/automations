#!/bin/bash

set -e

# =========================

# Colors

# =========================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

STATE_FILE="/etc/ufw_manager_installed"

# =========================

# Detect SSH Port

# =========================

get_ssh_port() {
PORT=$(grep -Ei '^Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | tail -n1)
echo ${PORT:-22}
}

# =========================

# Install & Initial Setup

# =========================

initial_setup() {

```
echo -e "${BLUE}===== Initial UFW Setup =====${NC}"

export DEBIAN_FRONTEND=noninteractive

if ! command -v ufw >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing UFW...${NC}"
    apt update -y
    apt install -y ufw
fi

echo -e "${YELLOW}Disabling UFW...${NC}"
ufw --force disable || true

echo -e "${YELLOW}Resetting rules...${NC}"
ufw --force reset

SSH_PORT=$(get_ssh_port)
echo -e "${GREEN}Detected SSH Port: $SSH_PORT${NC}"

echo -e "${YELLOW}Allowing SSH port...${NC}"
ufw allow ${SSH_PORT}/tcp

echo -e "${YELLOW}Enabling UFW...${NC}"
ufw --force enable

systemctl enable ufw >/dev/null 2>&1

touch $STATE_FILE

echo -e "${GREEN}UFW Installed and Configured Successfully!${NC}"
```

}

# =========================

# Show Status

# =========================

show_status() {

```
echo -e "${CYAN}\n===== UFW STATUS =====${NC}"

if ufw status | grep -q "Status: active"; then
    echo -e "Status: ${GREEN}ACTIVE${NC}"
else
    echo -e "Status: ${RED}INACTIVE${NC}"
fi

echo -e "\n${BLUE}Allowed Ports:${NC}"
ufw status numbered | sed '1,2d'
```

}

# =========================

# Add/Delete Ports

# =========================

manage_ports() {

```
echo -e "${CYAN}Enter ports (comma separated):${NC}"
read PORTS

IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

for PORT in "${PORT_ARRAY[@]}"; do
    PORT=$(echo $PORT | xargs)

    if ufw status | grep -w "$PORT" >/dev/null 2>&1; then
        echo -e "${RED}Removing port $PORT${NC}"
        ufw delete allow $PORT || true
    else
        echo -e "${GREEN}Adding port $PORT${NC}"
        ufw allow $PORT
    fi
done

echo -e "${YELLOW}Reloading UFW...${NC}"
ufw reload
```

}

# =========================

# Menu

# =========================

menu() {

```
while true; do
    show_status

    echo -e "\n${YELLOW}Choose an option:${NC}"
    echo -e "1) Add/Delete Port"
    echo -e "2) Disable UFW"
    echo -e "3) Enable UFW"
    echo -e "4) Exit"

    read -p "Enter choice: " choice

    case $choice in
        1)
            manage_ports
            ;;
        2)
            echo -e "${RED}Disabling UFW...${NC}"
            ufw disable
            ;;
        3)
            echo -e "${GREEN}Enabling UFW...${NC}"
            ufw enable
            ;;
        4)
            echo -e "${BLUE}Bye 👋${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
done
```

}

# =========================

# Main Logic

# =========================

if [ ! -f "$STATE_FILE" ]; then
initial_setup
else
menu
fi
