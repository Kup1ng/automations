#!/bin/bash

# =============================

# Colors

# =============================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================

# Root Check

# =============================

if [ "$EUID" -ne 0 ]; then
echo -e "${RED}Please run as root${NC}"
exit 1
fi

# =============================

# Detect SSH Port

# =============================

get_ssh_port() {
PORT=$(grep -Ei '^Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -n1)
[ -z "$PORT" ] && PORT=22
echo $PORT
}

SSH_PORT=$(get_ssh_port)

# =============================

# Install UFW if needed

# =============================

if ! command -v ufw >/dev/null 2>&1; then
echo -e "${YELLOW}Installing UFW...${NC}"
apt update -y >/dev/null 2>&1
apt install -y ufw >/dev/null 2>&1
fi

# =============================

# First Run Setup

# =============================

if [ ! -f /etc/ufw/.ufw_initialized ]; then
echo -e "${CYAN}First-time setup...${NC}"

```
ufw --force disable >/dev/null 2>&1
ufw reset >/dev/null 2>&1

echo -e "${GREEN}Adding SSH port: $SSH_PORT${NC}"
ufw allow $SSH_PORT/tcp >/dev/null 2>&1

ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

ufw --force enable >/dev/null 2>&1

touch /etc/ufw/.ufw_initialized

echo -e "${GREEN}UFW initialized successfully!${NC}"
```

fi

# =============================

# Status Display

# =============================

show_status() {
echo -e "\n${BLUE}========== UFW STATUS ==========${NC}"

```
if ufw status | grep -q "Status: active"; then
    echo -e "${GREEN}UFW is ACTIVE${NC}"
else
    echo -e "${RED}UFW is INACTIVE${NC}"
fi

echo -e "\n${YELLOW}Open Ports:${NC}"
ufw status numbered | grep -E 'ALLOW|DENY' | sed 's/^/  /'

echo -e "${BLUE}================================${NC}\n"
```

}

# =============================

# Add/Delete Ports

# =============================

manage_ports() {
read -p "Enter ports (comma separated): " INPUT

```
IFS=',' read -ra PORTS <<< "$INPUT"

for PORT in "${PORTS[@]}"; do
    PORT=$(echo $PORT | xargs)

    if [ "$PORT" == "$SSH_PORT" ]; then
        echo -e "${RED}Skipping SSH port ($SSH_PORT) for safety${NC}"
        continue
    fi

    if ufw status | grep -w "$PORT" | grep -q ALLOW; then
        echo -e "${YELLOW}Removing port $PORT${NC}"
        ufw delete allow $PORT >/dev/null 2>&1
    else
        echo -e "${GREEN}Adding port $PORT${NC}"
        ufw allow $PORT >/dev/null 2>&1
    fi
done

echo -e "${CYAN}Reloading UFW...${NC}"
ufw reload >/dev/null 2>&1
```

}

# =============================

# Menu

# =============================

while true; do
show_status

```
echo -e "${CYAN}Choose an option:${NC}"
echo -e "${GREEN}1) Add/Delete Port${NC}"
echo -e "${YELLOW}2) Disable UFW${NC}"
echo -e "${GREEN}3) Enable UFW${NC}"
echo -e "${RED}4) Exit${NC}"

read -p "Enter choice [1-4]: " CHOICE

case $CHOICE in
    1)
        manage_ports
        ;;
    2)
        ufw disable >/dev/null 2>&1
        echo -e "${RED}UFW Disabled${NC}"
        ;;
    3)
        ufw --force enable >/dev/null 2>&1
        echo -e "${GREEN}UFW Enabled${NC}"
        ;;
    4)
        echo -e "${BLUE}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        ;;
esac
```

done
