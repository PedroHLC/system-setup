#!/usr/bin/env sh
set -o errexit
cd /mnt

# clear
yes | sudo arch-chroot . pacman -Scc

# umount
cd /
sudo umount ./boot
sudo zfs umount -a
sudo zpool export zroot