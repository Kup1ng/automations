#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# Detect SSH Port

SSH_PORT=$(ss -tnlp | grep sshd | awk '{print $4}' | sed 's/.*://g' | head -n1)
[ -z "$SSH_PORT" ] && SSH_PORT=22

# Check if UFW installed

if ! command -v ufw >/dev/null 2>&1; then
echo "Installing UFW..."
apt update -y
apt install -y ufw
fi

# Detect first run

FIRST_RUN_FLAG="/etc/ufw/.managed_by_script"

if [ ! -f "$FIRST_RUN_FLAG" ]; then
echo "===== First Run: Initializing UFW ====="

```
ufw --force disable || true
ufw --force reset

# Allow SSH
ufw allow $SSH_PORT/tcp

ufw --force enable

touch $FIRST_RUN_FLAG

echo "UFW initialized and SSH port ($SSH_PORT) allowed."
exit 0
```

fi

# =========================

# STATUS FUNCTION

# =========================

show_status() {
echo ""
echo "===== UFW STATUS ====="

```
if ufw status | grep -q "Status: active"; then
    echo "Firewall Status : ACTIVE"
else
    echo "Firewall Status : INACTIVE"
fi

echo ""
echo "Allowed Ports:"
ufw status numbered | grep -E "ALLOW" || echo "No ports allowed"

echo ""
```

}

# =========================

# ADD / DELETE PORTS

# =========================

manage_ports() {
read -p "Enter ports (comma separated): " PORTS

```
IFS=',' read -ra PORT_ARRAY <<< "$PORTS"

for PORT in "${PORT_ARRAY[@]}"; do
    PORT=$(echo $PORT | xargs)

    [ -z "$PORT" ] && continue

    if [ "$PORT" == "$SSH_PORT" ]; then
        echo "Skipping SSH port ($SSH_PORT)"
        continue
    fi

    if ufw status | grep -q "$PORT"; then
        echo "Removing port $PORT"
        ufw delete allow $PORT/tcp || true
        ufw delete allow $PORT/udp || true
    else
        echo "Adding port $PORT"
        ufw allow $PORT
    fi
done

echo "Reloading UFW..."
ufw reload
```

}

# =========================

# MENU

# =========================

while true; do
show_status

```
echo "Select an option:"
echo "1) Add/Delete port"
echo "2) Disable UFW"
echo "3) Enable UFW"
echo "4) Exit"

read -p "Enter choice [1-4]: " CHOICE

case $CHOICE in
    1)
        manage_ports
        ;;
    2)
        ufw disable
        echo "UFW Disabled"
        ;;
    3)
        ufw enable
        echo "UFW Enabled"
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option"
        ;;
esac
```

done
