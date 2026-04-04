#!/usr/bin/env bash

set -e

# =============================

# Colors (safe with printf)

# =============================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

cecho() {
printf "%b%s%b\n" "$1" "$2" "$NC"
}

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
cecho "$YELLOW" "Installing UFW..."
export DEBIAN_FRONTEND=noninteractive
apt update -y >/dev/null 2>&1
apt install -y ufw >/dev/null 2>&1
fi

# =============================

# First Run Setup

# =============================

if [ ! -f /etc/ufw/.ufw_initialized ]; then
cecho "$CYAN" "First-time setup..."

```
ufw --force disable >/dev/null 2>&1
ufw --force reset >/dev/null 2>&1

cecho "$GREEN" "Adding SSH port: $SSH_PORT"
ufw allow "$SSH_PORT"/tcp >/dev/null 2>&1

ufw default deny incoming >/dev/null 2>&1
ufw default allow outgoing >/dev/null 2>&1

ufw --force enable >/dev/null 2>&1

touch /etc/ufw/.ufw_initialized

cecho "$GREEN" "UFW initialized successfully!"
```

fi

# =============================

# Status Display

# =============================

show_status() {
printf "\n"
cecho "$BLUE" "========== UFW STATUS =========="

```
if ufw status | grep -q "Status: active"; then
    cecho "$GREEN" "UFW is ACTIVE"
else
    cecho "$RED" "UFW is INACTIVE"
fi

printf "\n"
cecho "$YELLOW" "Open Ports:"
ufw status numbered | grep -E 'ALLOW|DENY' | sed 's/^/  /'

cecho "$BLUE" "================================"
printf "\n"
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
        cecho "$RED" "Skipping SSH port ($SSH_PORT)"
        continue
    fi

    if ufw status | grep -w "$PORT" | grep -q ALLOW; then
        cecho "$YELLOW" "Removing port $PORT"
        ufw delete allow "$PORT" >/dev/null 2>&1
    else
        cecho "$GREEN" "Adding port $PORT"
        ufw allow "$PORT" >/dev/null 2>&1
    fi
done

cecho "$CYAN" "Reloading UFW..."
ufw reload >/dev/null 2>&1
```

}

# =============================

# Menu

# =============================

while true; do
show_status

```
cecho "$CYAN" "Choose an option:"
cecho "$GREEN" "1) Add/Delete Port"
cecho "$YELLOW" "2) Disable UFW"
cecho "$GREEN" "3) Enable UFW"
cecho "$RED" "4) Exit"

read -r -p "Enter choice [1-4]: " CHOICE

case "$CHOICE" in
    1) manage_ports ;;
    2)
        ufw disable >/dev/null 2>&1
        cecho "$RED" "UFW Disabled"
        ;;
    3)
        ufw --force enable >/dev/null 2>&1
        cecho "$GREEN" "UFW Enabled"
        ;;
    4)
        cecho "$BLUE" "Goodbye!"
        exit 0
        ;;
    *)
        cecho "$RED" "Invalid option"
        ;;
esac
```

done
