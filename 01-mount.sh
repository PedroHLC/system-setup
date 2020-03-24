#!/usr/bin/env sh
set -o errexit

# mount in /mnt
sudo zpool export zroot
sudo zpool import -d /dev/sdb2 -R /mnt zroot
cd /mnt

sudo mkdir ./boot

# mount boot
sudo mount /dev/sdb1 ./boot

echo 'Finished'