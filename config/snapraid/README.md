# Snapraid Configuration

Place your `snapraid.conf` file here.

Example structure:
```
# Parity files
parity /mnt/parity1/snapraid.parity

# Content files (on data disks)
content /mnt/disk1/snapraid.content
content /mnt/disk2/snapraid.content
content /var/snapraid.content

# Data disks
data d1 /mnt/disk1
data d2 /mnt/disk2
data d3 /mnt/disk3

# Excludes
exclude *.unrecoverable
exclude /tmp/
exclude /lost+found/
```

Also create systemd timer/service files in `config/systemd/` for automated snapraid syncs.
