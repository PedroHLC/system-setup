#!/usr/bin/env sh
set -o errexit
cd /mnt

# install base
sudo pacstrap -GM . base

# genfstab (without ZFS cause we use zfs-mount)
genfstab -U /mnt | sed 's/^zroot/#zroot/' | sudo tee -a ./etc/fstab
echo '/dev/zvol/zroot/swap none swap discard 0 0' | sudo tee -a ./etc/fstab

echo 'Finished'