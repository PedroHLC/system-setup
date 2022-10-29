#!/usr/bin/env sh
set -o errexit

# Create EFI.
mkfs.vfat -F32 /dev/nvme0n1p1

# Create pool.
zpool create -f zroot /dev/nvme{0n1p2,1n1p1}
zpool set autotrim=on zroot
zfs set compression=lz4 zroot
zfs set mountpoint=none zroot

# System volumes.
zfs create -o mountpoint=none zroot/data
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=/ zroot/ROOT/default
zfs create -o mountpoint=/home zroot/data/home
zfs create -o mountpoint=/etc/ssh zroot/data/ssh
zfs create -o mountpoint=/etc/NetworkManager/system-connections zroot/data/connections
#zfs create -o mountpoint=/nix zroot/nix (TODO)

# Different recordsize
zfs create -o mountpoint=/home/pedrohlc/.cache/btdownloads -o recordsize=16K zroot/data/btdownloads
zfs create -o mountpoint=none -o recordsize=1M zroot/games
zfs create -o mountpoint=/home/pedrohlc/.local/share/Steam/steamapps/common zroot/games/steam
zfs create -o mountpoint=/home/pedrohlc/Games zroot/games/home

# Encrypted volumes.
zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/media/encrypted zroot/data/encrypted
zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/home/pedrohlc/.mozilla zroot/data/mozilla

# Swaps.
mkswap /dev/nvme0n1p3
mkswap /dev/nvme1n1p2
swapon /dev/nvme0n1p3
swapon /dev/nvme1n1p2

echo 'Finished. After installing NixOS, change every mountpoint to legacy.'
