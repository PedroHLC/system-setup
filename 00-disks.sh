#!/usr/bin/env sh
set -o errexit

# create boot
mkfs.vfat -F32 /dev/sdb1

# create rootfs
zpool create -f zroot /dev/nvme{0n1p2,1n1p1}
zpool set autotrim=on zroot
zfs set compression=lz4 zroot
zfs set mountpoint=none zroot
zfs create -o mountpoint=none zroot/data
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ zroot/ROOT/default
zfs create -o mountpoint=/home zroot/data/home
zfs create -o mountpoint=/etc/ssh zroot/data/ssh
zfs create -o mountpoint=/etc/NetworkManager/system-connections zroot/data/connections
zfs create -o mountpoint=/usr/local zroot/data/usr-local
zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/media/encrypted zroot/data/encrypted
zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/home/pedrohlc/.mozilla zroot/data/mozilla
#zfs create -o compression=zstd-2
zfs create \
    -o mountpoint=/home/pedrohlc/.local/share/Steam zroot/data/steam
zpool set bootfs=zroot/ROOT/default zroot
zpool set cachefile=/etc/zfs/zpool.cache zroot


mkswap /dev/nvme0n1p3
mkswap /dev/nvme1n1p3
swapon /dev/nvme0n1p3
swapon /dev/nvme1n1p3

echo 'Finished'