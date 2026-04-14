#!/bin/bash

set -e

echo "===== Starting Server Setup ====="

# Detect Ubuntu version and codename
. /etc/os-release
UBUNTU_VERSION_ID="${VERSION_ID}"
UBUNTU_CODENAME="${VERSION_CODENAME}"

echo "Detected Ubuntu version: ${UBUNTU_VERSION_ID}"
echo "Detected Ubuntu codename: ${UBUNTU_CODENAME}"

# Detect main network interface (with public IP)
MAIN_IF=$(ip -4 route get 1.1.1.1 | awk '{print $5}' | head -n1)
echo "Main Interface: $MAIN_IF"

# =========================
# Fix APT Sources
# =========================
echo "===== Fixing APT Sources ====="

if [[ "${UBUNTU_VERSION_ID}" == "22.04" ]]; then
    echo "Configuring APT sources for Ubuntu 22"

    cat > /etc/apt/sources.list <<EOF
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME} main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu ${UBUNTU_CODENAME}-security main restricted universe multiverse
EOF

elif [[ "${UBUNTU_VERSION_ID}" == "24.04" ]]; then
    echo "Configuring APT sources for Ubuntu 24"

    # Prevent duplicate source definitions
    : > /etc/apt/sources.list

    cat > /etc/apt/sources.list.d/ubuntu.sources <<EOF
Types: deb
URIs: http://archive.ubuntu.com/ubuntu/
Suites: ${UBUNTU_CODENAME} ${UBUNTU_CODENAME}-updates ${UBUNTU_CODENAME}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: ${UBUNTU_CODENAME}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

else
    echo "Unsupported Ubuntu version: ${UBUNTU_VERSION_ID}"
    exit 1
fi

# =========================
# Configure DNS
# =========================
echo "===== Configuring DNS ====="

if systemctl is-active systemd-resolved >/dev/null 2>&1; then
    echo "Using systemd-resolved"

    mkdir -p /etc/systemd/resolved.conf.d

    cat > /etc/systemd/resolved.conf.d/dns.conf <<EOF
[Resolve]
DNS=1.1.1.1 8.8.8.8
FallbackDNS=
EOF

    systemctl restart systemd-resolved
else
    echo "Using /etc/resolv.conf"

    rm -f /etc/resolv.conf

    cat > /etc/resolv.conf <<EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF

    chattr +i /etc/resolv.conf
fi

# =========================
# Update system
# =========================
echo "===== Updating system ====="
export DEBIAN_FRONTEND=noninteractive
apt update -y

# =========================
# Install packages
# =========================
echo "===== Installing packages ====="

apt install -y \
wget nano nload snapd iperf3 traceroute curl git jq apt-transport-https unzip apt-utils \
bash-completion busybox ca-certificates cron gnupg2 locales lsb-release preload screen \
software-properties-common ufw vim xxd zip autoconf automake build-essential libtool make \
pkg-config bc binutils binutils-common binutils-x86-64-linux-gnu ubuntu-keyring haveged \
libsodium-dev libsqlite3-dev libssl-dev packagekit qrencode socat dialog htop net-tools btop

# =========================
# Install Snap package
# =========================
echo "===== Installing speedtest ====="
snap install speedtest

# =========================
# Install Docker
# =========================
echo "===== Installing Docker ====="
curl -4 -fsSL https://get.docker.com | sh

apt install docker-compose -y

# =========================
# Enable BBR + Network tuning
# =========================
echo "===== Applying sysctl settings ====="

grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf || echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf || echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
grep -q "net.ipv4.tcp_fastopen = 3" /etc/sysctl.conf || echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf

sysctl -p

# =========================
# Done
# =========================
echo "===== Setup Completed - Rebooting ====="

reboot
