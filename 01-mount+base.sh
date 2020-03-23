#!/usr/bin/env sh
set -o errexit

# mount in /mnt
sudo zpool export zroot
sudo zpool import -d /dev/sdb2 -R /mnt zroot
cd /mnt

# install base
sudo pacstrap -GM . base

# mount boot
sudo mount /dev/sdb1 /mnt/boot

# genfstab (without ZFS cause we use zfs-mount)
genfstab -U /mnt | sed 's/^zroot/#zroot/' | sudo tee -a ./etc/fstab
echo '/dev/zvol/zroot/swap none swap discard 0 0' | sudo tee -a ./etc/fstab
