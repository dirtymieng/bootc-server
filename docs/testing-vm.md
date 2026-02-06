# Testing the bootc Image in a VM

This guide covers building a qcow2 image and testing it locally with libvirt.

## Prerequisites

- podman
- libvirt + qemu
- virt-install (`sudo pacman -S virt-install` on Arch/CachyOS)

## 1. Build the Container Image

```bash
./scripts/build.sh
```

## 2. Export the Image

Export from user storage so root podman can access it:

```bash
mkdir -p output
podman save -o output/my-server.tar localhost/my-server:latest
```

## 3. Load into Root Storage

```bash
sudo podman load -i output/my-server.tar
```

## 4. Create Test User Config (Optional)

Create a config file to add a user for login:

```bash
cat > output/config.toml << 'EOF'
[[customizations.user]]
name = "dirtymieng"
password = "changeme"
groups = ["wheel"]
EOF
```

Or with SSH key instead of password:

```toml
[[customizations.user]]
name = "dirtymieng"
groups = ["wheel"]
key = "ssh-ed25519 AAAA..."
```

## 5. Build the qcow2 Image

Pull bootc-image-builder (only needed once):

```bash
sudo podman pull quay.io/centos-bootc/bootc-image-builder:latest
```

Build the qcow2:

```bash
sudo podman run --rm -it --privileged \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v ./output:/output \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 \
  --rootfs xfs \
  --config /output/config.toml \
  localhost/my-server:latest
```

Without user config, omit `--config /output/config.toml`.

## 6. Deploy to libvirt

Copy to libvirt images directory:

```bash
sudo cp ./output/qcow2/disk.qcow2 /var/lib/libvirt/images/bootc-test.qcow2
sudo chown qemu:qemu /var/lib/libvirt/images/bootc-test.qcow2
```

Ensure default network is active:

```bash
sudo virsh net-start default
sudo virsh net-autostart default
```

## 7. Boot the VM

```bash
sudo virt-install --name bootc-test \
  --memory 2048 --vcpus 2 \
  --disk /var/lib/libvirt/images/bootc-test.qcow2 \
  --import --os-variant fedora42 \
  --graphics none --console pty,target_type=serial
```

## 8. Connect to the VM

Serial console:

```bash
sudo virsh console bootc-test
```

Exit with `Ctrl+]`.

Get VM IP for Cockpit/SSH:

```bash
sudo virsh domifaddr bootc-test
```

Then access Cockpit at `https://<ip>:9090`.

## 9. Cleanup

```bash
sudo virsh destroy bootc-test
sudo virsh undefine bootc-test
sudo rm /var/lib/libvirt/images/bootc-test.qcow2
```

## Troubleshooting

**"Permission denied" on disk image:**
- Ensure file is in `/var/lib/libvirt/images/`
- Run `sudo chown qemu:qemu <image>`

**"network 'default' is not active":**
- Run `sudo virsh net-start default`

**Can't login - no user:**
- Rebuild with `--config` option and a config.toml defining a user
