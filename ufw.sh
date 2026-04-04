#!/bin/bash

set -e

STATE_FILE="/etc/ufw_manager_initialized"

# =========================
# Get SSH Port
# =========================
get_ssh_port() {
    PORT=$(grep -i "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | tail -n1)
    echo "${PORT:-22}"
}

SSH_PORT=$(get_ssh_port)

# =========================
# Install UFW if not exists
# =========================
install_ufw() {
    if ! command -v ufw >/dev/null 2>&1; then
        echo "Installing UFW..."
        export DEBIAN_FRONTEND=noninteractive
        apt update -y
        apt install -y ufw
    fi
}

# =========================
# First time setup
# =========================
first_time_setup() {
    echo "===== First Time UFW Setup ====="

    install_ufw

    ufw --force disable
    ufw --force reset

    echo "Allowing SSH port: $SSH_PORT"
    ufw allow "$SSH_PORT"/tcp

    ufw --force enable

    touch "$STATE_FILE"

    echo "UFW initialized successfully."
}

# =========================
# Show status
# =========================
show_status() {
    echo "=============================="
    echo "UFW Status: $(ufw status | head -n1)"
    echo "------------------------------"
    echo "Allowed Ports:"
    ufw status numbered | sed '1,2d'
    echo "=============================="
}

# =========================
# Toggle ports
# =========================
manage_ports() {
    read -p "Enter ports (comma separated): " INPUT

    IFS=',' read -ra PORTS <<< "$INPUT"

    for PORT in "${PORTS[@]}"; do
        PORT=$(echo "$PORT" | xargs)

        if [[ "$PORT" == "$SSH_PORT" ]]; then
            echo "Skipping SSH port ($SSH_PORT)"
            continue
        fi

        if ufw status | grep -qw "$PORT"; then
            echo "Deleting port: $PORT"
            ufw delete allow "$PORT" >/dev/null 2>&1 || true
        else
            echo "Adding port: $PORT"
            ufw allow "$PORT" >/dev/null 2>&1
        fi
    done

    ufw reload
    echo "Done."
}

# =========================
# Menu
# =========================
menu() {
    while true; do
        show_status

        echo "1 - Add/Delete port"
        echo "2 - Disable UFW"
        echo "3 - Enable UFW"
        echo "4 - Exit"

        read -p "Select option: " CHOICE

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
                exit 0
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
    done
}

# =========================
# Main
# =========================
if [[ ! -f "$STATE_FILE" ]]; then
    first_time_setup
else
    install_ufw
    menu
fi
