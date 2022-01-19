#!/usr/bin/env sh
set -o errexit
cd /mnt

# install base
pacstrap -GM . base

# genfstab (without ZFS cause we use zfs-mount)
genfstab -U /mnt | sed 's/^zroot/#zroot/g' | tee -a ./etc/fstab

# giant tmpfs
echo 'tmpfs /tmp tmpfs rw,nosuid,nodev,size=67108864k,nr_inodes=0,inode64 0 0'  | tee -a ./etc/fstab

echo 'Finished'