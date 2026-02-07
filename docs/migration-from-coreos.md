# Migration from CoreOS/uCore to bootc

Minimal-downtime migration checklist for replacing the existing CoreOS server.

## Pre-Migration (Do While CoreOS Running)

### 1. Push Image to Backup Registry

```bash
# On dev machine - login to GitHub Container Registry
echo $GITHUB_TOKEN | podman login ghcr.io -u dirtymieng --password-stdin

# Build and push
REGISTRY=ghcr.io/dirtymieng ./scripts/build.sh
```

### 2. Backup Container Data

SSH into CoreOS server and backup persistent data:

```bash
# Create backup directory
mkdir -p /tmp/backups

# Omada Controller (network management)
sudo tar -czvf /tmp/backups/omada.tar.gz -C /var/lib/media_conf Omada

# Frigate (NVR)
sudo tar -czvf /tmp/backups/frigate.tar.gz -C /var/lib/media_conf Frigate

# Forgejo (git/registry)
sudo tar -czvf /tmp/backups/forgejo.tar.gz -C /var/lib/media_conf Forgejo

# Caddy (reverse proxy)
sudo tar -czvf /tmp/backups/caddy.tar.gz -C /var/lib/media_conf Caddy

# Any other services
sudo tar -czvf /tmp/backups/jellyfin.tar.gz -C /var/lib/media_conf Jellyfin
sudo tar -czvf /tmp/backups/sonarr.tar.gz -C /var/lib/media_conf Sonarr
sudo tar -czvf /tmp/backups/radarr.tar.gz -C /var/lib/media_conf Radarr
sudo tar -czvf /tmp/backups/nzbget.tar.gz -C /var/lib/media_conf NzbGet
```

### 3. Copy Backups Off Server

```bash
# From dev machine
scp -r dirtymieng@<coreos-ip>:/tmp/backups ./backups/
```

Or copy to USB drive.

### 4. Verify Config Repo is Complete

Ensure all configs are committed:
- [ ] Quadlets in `config/containers/`
- [ ] SystemD units in `config/systemd/`
- [ ] NetworkManager configs in `config/networkmanager/`
- [ ] Samba config in `config/samba/`
- [ ] App configs in `config/app-configs/`

### 5. Prepare Live USB

Download Fedora CoreOS live ISO and write to USB:

```bash
curl -LO https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/41.20250303.3.0/x86_64/fedora-coreos-41.20250303.3.0-live.x86_64.iso
sudo dd if=fedora-coreos-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

---

## Cutover (Expect 10-15 min downtime)

### 1. Shutdown CoreOS

```bash
sudo shutdown now
```

### 2. Boot from USB

Boot the server from the Fedora CoreOS live USB.

### 3. Install bootc Image

```bash
sudo podman run --rm --privileged --pid=host \
  -v /dev:/dev -v /var/lib/containers:/var/lib/containers \
  --security-opt label=disable \
  docker://ghcr.io/dirtymieng/bootc-server:latest \
  bootc install to-disk --wipe --filesystem xfs /dev/sda
```

### 4. Reboot

Remove USB and reboot into new system.

---

## Post-Install Configuration

### 1. SSH In

```bash
ssh dirtymieng@<server-ip>
```

### 2. Set Hostname

```bash
sudo hostnamectl set-hostname peenas
```

### 3. Prevent DHCP Hostname Override

```bash
sudo tee /etc/NetworkManager/conf.d/no-hostname.conf << 'EOF'
[main]
hostname-mode=none
EOF
sudo systemctl restart NetworkManager
```

### 4. Clone Config Repo

```bash
cd ~
git clone https://forgejo.meatworks.org/dirtymieng/bootc-server.git
# Or from GitHub if Forgejo not yet available:
# git clone https://github.com/dirtymieng/bootc-server.git
```

### 5. Deploy Configuration

```bash
cd bootc-server
sudo ./scripts/deploy-config.sh
```

### 6. Create Data Directories

```bash
sudo mkdir -p /var/lib/media_conf
sudo mkdir -p /var/mnt/hdd
sudo mkdir -p /var/mnt/media
sudo mkdir -p /var/mnt/nvr
```

### 7. Restore Backups

Copy backups to server (via USB or scp), then:

```bash
# Restore all service data
sudo tar -xzvf backups/omada.tar.gz -C /var/lib/media_conf
sudo tar -xzvf backups/frigate.tar.gz -C /var/lib/media_conf
sudo tar -xzvf backups/forgejo.tar.gz -C /var/lib/media_conf
sudo tar -xzvf backups/caddy.tar.gz -C /var/lib/media_conf
sudo tar -xzvf backups/jellyfin.tar.gz -C /var/lib/media_conf
sudo tar -xzvf backups/sonarr.tar.gz -C /var/lib/media_conf
sudo tar -xzvf backups/radarr.tar.gz -C /var/lib/media_conf
sudo tar -xzvf backups/nzbget.tar.gz -C /var/lib/media_conf
```

### 8. Enable and Start Mount Units

```bash
sudo systemctl enable --now var-mnt-hdd-2TB\\x2dWMC300199477.mount
sudo systemctl enable --now var-mnt-hdd-2TB\\x2dWMC300210354.mount
sudo systemctl enable --now var-mnt-nvr.automount
sudo systemctl enable --now mergerfs.service
```

### 9. Create Podman Secret for Caddy

```bash
echo "your-cloudflare-api-token" | sudo podman secret create cf-api-token -
```

### 10. Start Container Services

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now caddy
sudo systemctl enable --now forgejo
sudo systemctl enable --now frigate
sudo systemctl enable --now jellyfin
sudo systemctl enable --now omada
sudo systemctl enable --now sonarr
sudo systemctl enable --now radarr
sudo systemctl enable --now nzbget
```

### 11. Verify Services

```bash
sudo systemctl status caddy forgejo frigate jellyfin omada
sudo podman ps
```

---

## Post-Migration

### Update Registry in build.sh

Once Forgejo is back up, update `scripts/build.sh` to push to your own registry:

```bash
REGISTRY="${REGISTRY:-forgejo.meatworks.org/dirtymieng}"
```

### Test Everything

- [ ] Cockpit accessible at https://<ip>:9090
- [ ] Omada controller managing APs
- [ ] Frigate detecting cameras
- [ ] Jellyfin serving media
- [ ] Forgejo accessible, can push images
- [ ] Samba shares accessible
- [ ] mergerfs pool mounted at /var/mnt/media

---

## Rollback Plan

If something goes wrong, boot from USB and reinstall CoreOS/uCore from their image, then restore backups.

## Services During Downtime

| Service | Impact |
|---------|--------|
| Omada | APs keep working on cached config, no management |
| Frigate | Cameras buffer locally, missed recordings |
| Jellyfin | Unavailable |
| Forgejo | Unavailable |
| Samba | Unavailable |
