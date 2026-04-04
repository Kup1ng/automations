#!/usr/bin/env bash

set -e

# Fix potential CRLF issues (important for curl اجرا)

sed -i 's/\r$//' "$0" 2>/dev/null || true

# =============================

# Colors (safe)

# =============================

RED=$(printf '\033[0;31m')
GREEN=$(printf '\033[0;32m')
YELLOW=$(printf '\033[1;33m')
BLUE=$(printf '\033[0;34m')
CYAN=$(printf '\033[0;36m')
NC=$(printf '\033[0m')

# =============================

# Root Check

# =============================

if [ "$EUID" -ne 0 ]; then
echo "Please run as root"
exit 1
fi

# =============================

# Detect SSH Port

# =============================

get_ssh_port() {
PORT=$(awk '/^Port / {print $2}' /etc/ssh/sshd_config 2>/dev/null | head -n1)
[ -z "$PORT" ] && PORT=22
echo "$PORT"
}

SSH_PORT=$(get_ssh_port)

# =============================

# Install UFW if needed

# =============================

if ! command -v ufw >/dev/null 2>&1; then
echo "${YELLOW}Installing UFW...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update -y >/dev/null 2>&1
apt install -y ufw >/dev/null 2>&1
fi

# =============================

# First Run Setup

# =============================

if [ ! -f /etc/ufw/.ufw_initialized ]; then
echo "${CYAN}First-time setup...${NC}"

```
ufw --force disable >/dev/null 2>&1
ufw --force reset >/dev/null 2>&1

echo "${GREEN}Adding SSH port: $SSH_PORT${NC}"
ufw allow "$SSH_PORT"/tcp >/dev/null 2>&1

ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

ufw --force enable >/dev/null 2>&1

touch /etc/ufw/.ufw_initialized

echo "${GREEN}UFW initialized successfully!${NC}"
```

fi

# =============================

# Status Display

# =============================

show_status() {
echo
echo "${BLUE}========== UFW STATUS ==========${NC}"

```
if ufw status | grep -q "Status: active"; then
    echo "${GREEN}UFW is ACTIVE${NC}"
else
    echo "${RED}UFW is INACTIVE${NC}"
fi

echo
echo "${YELLOW}Open Ports:${NC}"
ufw status numbered | grep -E 'ALLOW|DENY' | sed 's/^/  /'

echo "${BLUE}================================${NC}"
echo
```

}

# =============================

# Add/Delete Ports

# =============================

manage_ports() {
read -r -p "Enter ports (comma separated): " INPUT

```
IFS=',' read -ra PORTS <<< "$INPUT"

for PORT in "${PORTS[@]}"; do
    PORT=$(echo "$PORT" | xargs)

    if [ "$PORT" = "$SSH_PORT" ]; then
        echo "${RED}Skipping SSH port ($SSH_PORT) for safety${NC}"
        continue
    fi

    if ufw status | grep -w "$PORT" | grep -q ALLOW; then
        echo "${YELLOW}Removing port $PORT${NC}"
        ufw delete allow "$PORT" >/dev/null 2>&1
    else
        echo "${GREEN}Adding port $PORT${NC}"
        ufw allow "$PORT" >/dev/null 2>&1
    fi
done

echo "${CYAN}Reloading UFW...${NC}"
ufw reload >/dev/null 2>&1
```

}

# =============================

# Menu

# =============================

while true; do
show_status

```
echo "${CYAN}Choose an option:${NC}"
echo "${GREEN}1) Add/Delete Port${NC}"
echo "${YELLOW}2) Disable UFW${NC}"
echo "${GREEN}3) Enable UFW${NC}"
echo "${RED}4) Exit${NC}"

read -r -p "Enter choice [1-4]: " CHOICE

case "$CHOICE" in
    1) manage_ports ;;
    2)
        ufw disable >/dev/null 2>&1
        echo "${RED}UFW Disabled${NC}"
        ;;
    3)
        ufw --force enable >/dev/null 2>&1
        echo "${GREEN}UFW Enabled${NC}"
        ;;
    4)
        echo "${BLUE}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo "${RED}Invalid option${NC}"
        ;;
esac
```

done
