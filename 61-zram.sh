#!/usr/bin/env sh
set -o errexit
cd /mnt

cat <<EOF | sudo tee ./etc/systemd/swap.conf > /dev/null
zram_enabled=1
zram_size=1024
zram_count=4
zram_streams=4
zram_alg=lz4
EOF

sudo systemctl --root=. enable systemd-swap
