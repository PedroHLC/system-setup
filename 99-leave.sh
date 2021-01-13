#!/usr/bin/env sh
set -o errexit
cd /mnt

# clear
yes | arch-chroot . pacman -Scc

# zpool.cache
cp /etc/zfs/zpool.cache ./etc/zfs/zpool.cache

# umount
cd /
umount ./boot
zfs umount -a
zpool export zroot

echo 'Finished'