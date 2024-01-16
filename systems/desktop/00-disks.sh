#!/usr/bin/env sh
set -o errexit

# Create EFI.
mkfs.vfat -F32 /dev/nvme0n1p1

# Swaps.
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2

# Create pool.
zpool create -f zroot /dev/nvme0n1p3
zpool set autotrim=on zroot
zfs set compression=lz4 zroot
zfs set mountpoint=none zroot
zfs create -o refreservation=8G -o mountpoint=none zroot/reserved

# System volumes.
zfs create -o mountpoint=none zroot/data
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=legacy zroot/ROOT/empty
zfs create -o mountpoint=legacy zroot/ROOT/nix
zfs create -o mountpoint=legacy zroot/ROOT/residues
zfs create -o mountpoint=legacy zroot/data/persistent

# Different recordsize
zfs create -o mountpoint=legacy -o recordsize=16K \
	-o compression=off zroot/data/btdownloads
zfs create -o mountpoint=none -o recordsize=1M zroot/games
zfs create -o mountpoint=legacy zroot/games/home
zfs create -o mountpoint=legacy -o recordsize=16K \
	-o logbias=latency zroot/data/postgres

# Encrypted volumes.
zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/home/pedrohlc/.encrypted zroot/data/encrypted
zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/home/pedrohlc/.mozilla zroot/data/mozilla

# Init structure
mount -t zfs zroot/ROOT/empty /mnt
mkdir -p /mnt/nix /mnt/home/pedrohlc/Games /mnt/home/pedrohlc/Torrents \
	/mnt/var/persistent /mnt/var/residues /mnt/boot
zfs snapshot zroot/ROOT/empty@start

# Mount & Permissions
mount /dev/nvme0n1p1 /mnt/boot
chmod 700 /mnt/boot
mount -t zfs zroot/ROOT/nix /mnt/nix
mount -t zfs zroot/games/home /mnt/home/pedrohlc/Games
mount -t zfs zroot/data/btdownloads /mnt/home/pedrohlc/Torrents
chown -R 1001:100 /mnt/home/pedrohlc
chmod 0750 /mnt/home/pedrohlc/Games
mount -t zfs zroot/data/persistent /mnt/var/persistent
mount -t zfs zroot/ROOT/residues /mnt/var/residues

# Podman
sudo zfs create -o mountpoint=none -o canmount=on zroot/containers

echo "Finished. But you\'ll need to set the postgresql volume permission and ownership eventually."
