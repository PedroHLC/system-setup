#!/usr/bin/env sh
set -o errexit
cd /mnt

# install base
pacstrap -GM . base

# genfstab (without ZFS cause we use zfs-mount)
genfstab -U /mnt | sed 's/^zroot/#zroot/g' | tee -a ./etc/fstab

echo 'Finished'