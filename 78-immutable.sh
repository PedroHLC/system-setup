#!/usr/bin/env sh
set -o errexit
cd /mnt

# Hook script
cat <<EOF | sudo tee ./etc/initcpio/hooks/immutable > /dev/null
mount -o remount,ro "$${rootmnt}"

mkdir -m 755 /run/rootfs
mount -t tmpfs -o size=90%,mode=755,suid,exec tmpfs /run/rootfs
mkdir -m 755 /run/rootfs/{ro,rw,.workdir}

mount -n -o move "$${rootmnt}" /run/rootfs/ro

mount -t overlay -o lowerdir=/run/rootfs/ro,upperdir=/run/rootfs/rw,workdir=/run/rootfs/.workdir root "$${rootmnt}"
EOF
sudo chmod 644 ./etc/initcpio/hooks/immutable

# Add Hook
sudo sed -i'' "s/zfs/zfs immutable/g" ./etc/mkinitcpio.conf