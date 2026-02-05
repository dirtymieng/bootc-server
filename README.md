# Bootc Fedora Server

Immutable Fedora server image for container-based workloads with mergerfs and snapraid support.

## Structure

```
bootc-server/
├── image/
│   └── Containerfile          # Minimal base image (packages only)
├── config/
│   ├── systemd/               # Systemd mount units and services
│   ├── containers/            # Podman quadlet definitions
│   ├── snapraid/              # Snapraid configuration
│   └── ssh/                   # SSH authorized keys
└── scripts/
    └── deploy-config.sh       # Configuration deployment script
```

## Setup

### 1. Build the Image

```bash
cd image
podman build -t my-server:latest .

# Tag and push to your registry
podman tag my-server:latest registry.example.com/my-server:latest
podman push registry.example.com/my-server:latest
```

### 2. Install to Server

Boot from a Fedora live USB or installer, then:

```bash
# Install your custom image to disk
bootc install to-disk --image registry.example.com/my-server:latest /dev/sda

# Reboot into the new system
reboot
```

### 3. Deploy Configuration

After first boot:

```bash
# Clone this repository
git clone <your-repo-url> ~/bootc-server
cd ~/bootc-server

# Copy your existing systemd units to config/systemd/
# Copy your existing quadlets to config/containers/
# Copy your snapraid.conf to config/snapraid/
# Add SSH keys to config/ssh/authorized_keys

# Deploy all configuration
./scripts/deploy-config.sh
```

### 4. Enable Your Services

```bash
# Enable mount units
sudo systemctl enable --now mnt-disk1.mount
sudo systemctl enable --now mnt-disk2.mount
sudo systemctl enable --now mnt-storage.mount

# Enable snapraid timer
sudo systemctl enable --now snapraid-sync.timer

# Container quadlets start automatically via systemd
```

## Usage

### Updating the Base Image

```bash
# Rebuild and push new image
cd image
podman build -t registry.example.com/my-server:latest .
podman push registry.example.com/my-server:latest

# On server: upgrade to new image
bootc upgrade --apply
reboot
```

### Updating Configuration

```bash
# Make changes to config files in git
git pull
./scripts/deploy-config.sh

# Restart affected services as needed
sudo systemctl restart myservice.service
```

### Managing Deployments

```bash
# Check current status
bootc status

# Upgrade to latest image
bootc upgrade --apply

# Rollback to previous deployment
bootc rollback
reboot
```

## Migration from CoreOS

Since you have existing CoreOS configuration:

1. Copy your systemd mount units to `config/systemd/`
2. Copy your podman quadlets to `config/containers/`
3. Copy your snapraid configuration to `config/snapraid/`
4. Add SSH keys to `config/ssh/authorized_keys`
5. Review and adjust any CoreOS-specific paths or settings
6. Deploy using the script above

## Notes

- The base image contains only packages - no configuration
- All configuration lives in `/etc` and is managed via git
- Data disks are mounted via systemd mount units (not in the image)
- Containers are managed via podman quadlets
- Updates to the base image are atomic and can be rolled back
