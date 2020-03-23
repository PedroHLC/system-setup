#!/usr/bin/env sh
set -o errexit
cd /mnt

# clear
yes | sudo arch-chroot . pacman -Scc

# zpool.cache
sudo cp /etc/zfs/zpool.cache ./etc/zfs/zpool.cache

# umount
cd /
sudo umount ./boot
sudo zfs umount -a
sudo zpool export zroot