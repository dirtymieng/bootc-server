# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Immutable Fedora 43 bootc server image with mergerfs storage pooling and snapraid parity protection. This is an infrastructure-as-code project, not a software application.

**Key concept:** The base image (`image/Containerfile`) contains only packages. All configuration is git-managed in `config/` and deployed to `/etc` via scripts.

## Commands

### Build Image
```bash
./scripts/build.sh                                    # Build locally
REGISTRY=registry.example.com ./scripts/build.sh     # Build and push
IMAGE_NAME=myserver:v1 ./scripts/build.sh            # Custom image name
```

### Deploy Configuration
```bash
sudo ./scripts/deploy-config.sh    # Deploy all config from config/ to /etc
```

### Server Management (on deployed system)
```bash
bootc status                       # Check current deployment
bootc upgrade --apply              # Pull and stage new image
bootc rollback                     # Rollback to previous deployment
```

## Architecture

```
image/Containerfile     → Base image: packages only, no config
config/systemd/         → Systemd mount units (.mount) and services
config/containers/      → Podman quadlets (.container files)
config/app-configs/     → Application configs (Caddy, Frigate, etc.) → /var/lib/media_conf/
config/snapraid/        → snapraid.conf
config/ssh/             → authorized_keys for root
scripts/build.sh        → Build OCI image with podman
scripts/deploy-config.sh → Copy config to /etc and /var/lib/media_conf, reload systemd
```

**Deployment flow:**
1. Build image → push to registry
2. Server: `bootc install to-disk` or `bootc upgrade`
3. Clone repo → run `deploy-config.sh`
4. Enable services: `systemctl enable --now <unit>`

**Update patterns:**
- Package changes → modify Containerfile, rebuild, `bootc upgrade`, reboot
- Config changes → git pull, run `deploy-config.sh`, restart affected services

## Tech Stack

- **OS:** Fedora 43 bootc (immutable, atomic updates)
- **Containers:** Podman with systemd quadlets
- **Storage:** mergerfs (pooling), snapraid (parity), FUSE
- **Virtualization:** qemu-kvm, libvirt
- **Management:** Cockpit web UI
