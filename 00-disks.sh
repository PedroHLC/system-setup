#!/usr/bin/env sh
set -o errexit

# create boot
sudo mkfs.vfat -F32 /dev/sdb1

# create rootfs
sudo zpool create -f zroot /dev/sdb2
sudo zpool set compression=lz4 zroot
sudo zpool set autotrim=on zroot
sudo zfs set mountpoint=none zroot
sudo zfs create -o mountpoint=none zroot/data
sudo zfs create -o mountpoint=none zroot/ROOT
sudo zfs create -o mountpoint=/ zroot/ROOT/default
sudo zfs create -o mountpoint=/home zroot/data/home
sudo zfs create -o mountpoint=/etc/ssh zroot/data/ssh
sudo zfs create -o mountpoint=/etc/NetworkManager/system-connections zroot/data/connections
sudo zfs create -o mountpoint=/usr/local zroot/data/usr-local
sudo zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/media/encrypted zroot/data/encrypted
sudo zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/home/pedrohlc/.mozilla zroot/data/mozilla
sudo zpool set bootfs=zroot/ROOT/default zroot
sudo zpool set cachefile=/etc/zfs/zpool.cache zroot

# swap
#sudo zfs create -V 8G -b $(getconf PAGESIZE) \
#	-o logbias=throughput -o sync=always\
#	-o primarycache=metadata \
#	-o com.sun:auto-snapshot=false zroot/swap
#mkswap -f /dev/zvol/zroot/swap
# NOTE: Don't do a ZFS swap, it's useless, you can't hibernate to it!

echo 'Finished'