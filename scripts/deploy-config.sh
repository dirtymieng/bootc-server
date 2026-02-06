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

# Deploy NetworkManager configs
if [ -d "${CONFIG_DIR}/networkmanager" ] && [ "$(ls -A ${CONFIG_DIR}/networkmanager)" ]; then
    echo "Deploying NetworkManager connections..."
    sudo cp ${CONFIG_DIR}/networkmanager/*.nmconnection /etc/NetworkManager/system-connections/
    sudo chmod 600 /etc/NetworkManager/system-connections/*.nmconnection
    sudo nmcli connection reload
fi

# Deploy application configs
if [ -d "${CONFIG_DIR}/app-configs" ] && [ "$(ls -A ${CONFIG_DIR}/app-configs)" ]; then
    echo "Deploying application configs..."
    for app_dir in ${CONFIG_DIR}/app-configs/*/; do
        app_name=$(basename "$app_dir")
        target_dir="/var/lib/media_conf/${app_name}"
        sudo mkdir -p "$target_dir"
        echo "  -> ${app_name}"
        sudo cp -r "${app_dir}"* "$target_dir/"
    done
fi

echo ""
echo "Configuration deployed successfully!"
echo ""
echo "Next steps:"
echo "1. Review deployed files:"
echo "   - /etc/systemd/system (systemd units)"
echo "   - /etc/containers/systemd (quadlets)"
echo "   - /etc/NetworkManager/system-connections (network config)"
echo "   - /var/lib/media_conf (app configs)"
echo "2. Enable and start your mount units:"
echo "   sudo systemctl enable --now mnt-disk1.mount"
echo "   sudo systemctl enable --now mnt-disk2.mount"
echo "   sudo systemctl enable --now mnt-storage.mount"
echo "3. Enable snapraid timer if configured:"
echo "   sudo systemctl enable --now snapraid-sync.timer"
echo "4. Start container services:"
echo "   sudo systemctl enable --now caddy jellyfin frigate ..."
echo "5. Check status with: systemctl status"
