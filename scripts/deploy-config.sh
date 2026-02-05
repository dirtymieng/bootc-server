#!/bin/bash
# Deploy configuration to bootc Fedora system

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${REPO_ROOT}/config"

echo "Deploying configuration from ${CONFIG_DIR}"

# Deploy systemd units
if [ -d "${CONFIG_DIR}/systemd" ] && [ "$(ls -A ${CONFIG_DIR}/systemd)" ]; then
    echo "Deploying systemd units..."
    sudo cp -r ${CONFIG_DIR}/systemd/* /etc/systemd/system/
    sudo systemctl daemon-reload
fi

# Deploy quadlets
if [ -d "${CONFIG_DIR}/containers" ] && [ "$(ls -A ${CONFIG_DIR}/containers)" ]; then
    echo "Deploying container quadlets..."
    sudo mkdir -p /etc/containers/systemd
    sudo cp -r ${CONFIG_DIR}/containers/* /etc/containers/systemd/
    sudo systemctl daemon-reload
fi

# Deploy snapraid config
if [ -f "${CONFIG_DIR}/snapraid/snapraid.conf" ]; then
    echo "Deploying snapraid configuration..."
    sudo cp ${CONFIG_DIR}/snapraid/snapraid.conf /etc/snapraid.conf
fi

# Deploy SSH keys
if [ -f "${CONFIG_DIR}/ssh/authorized_keys" ]; then
    echo "Deploying SSH authorized keys..."
    sudo mkdir -p /root/.ssh
    sudo cp ${CONFIG_DIR}/ssh/authorized_keys /root/.ssh/
    sudo chmod 600 /root/.ssh/authorized_keys
    sudo chmod 700 /root/.ssh
fi

echo ""
echo "Configuration deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Review deployed files in /etc/systemd/system and /etc/containers/systemd"
echo "2. Enable and start your mount units:"
echo "   sudo systemctl enable --now mnt-disk1.mount"
echo "   sudo systemctl enable --now mnt-disk2.mount"
echo "   sudo systemctl enable --now mnt-storage.mount"
echo "3. Enable snapraid timer if configured:"
echo "   sudo systemctl enable --now snapraid-sync.timer"
echo "4. Check status with: systemctl status"
