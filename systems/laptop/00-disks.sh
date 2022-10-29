#!/usr/bin/env sh
set -o errexit

# Swaps.
#mkswap /dev/nvme0n1p3 # (TODO)
#swapon /dev/nvme0n1p3 # (TODO)

# Create EFI.
mkfs.vfat -F32 /dev/nvme0n1p1

# Create ZFS pool.
zpool create -f zroot /dev/nvme0n1p2
zpool set autotrim=on zroot
zfs set compression=lz4 zroot
zfs set mountpoint=none zroot

# Top-level hierarchy.
zfs create -o mountpoint=none zroot/data
zfs create -o mountpoint=none zroot/ROOT
zfs create -o mountpoint=none zroot/apps
zfs create -o mountpoint=none zroot/guests
zfs create -o mountpoint=none -o recordsize=1M zroot/games

# System's filesystem
# zfs create -o mountpoint=/ zroot/ROOT/default # (LEGACY)
zfs create -o mountpoint=/ zroot/ROOT/empty
zfs create -o mountpoint=/nix zroot/ROOT/nix
zfs create -o mountpoint=/var/cache zroot/ROOT/var-cache
zfs create -o mountpoint=/var/log zroot/ROOT/var-log

# System's data
zfs create -o mountpoint=/etc/NetworkManager/system-connections zroot/data/connections
zfs create -o mountpoint=/etc/nixos zroot/data/setup
zfs create -o mountpoint=/etc/ssh zroot/data/sshd
zfs create -o mountpoint=/var/lib/bluetooth zroot/data/bluetooth
zfs create -o mountpoint=/var/lib/containers zroot/data/containers
zfs create -o mountpoint=/var/lib/flatpak zroot/data/flatpak
zfs create -o mountpoint=/var/lib/postgres \
	-o recordsize=16K -o primarycache=metadata \
	zroot/data/postgres
zfs create -o mountpoint=/var/lib/systemd zroot/data/systemd
zfs create -o mountpoint=/var/lib/upower zroot/data/upower

# Pedro's home
# zfs create -o mountpoint=/home zroot/data/home # (LEGACY)
zfs create -o mountpoint=/home/pedrohlc/.cache zroot/data/my-cache
zfs create -o mountpoint=/home/pedrohlc/.gnupg zroot/data/my-gnupg
zfs create -o mountpoint=/home/pedrohlc/.local/share/Steam zroot/apps/steam
zfs create -o mountpoint=/home/pedrohlc/.local/share/Steam/steamapps/common zroot/games/steam
zfs create -o mountpoint=/home/pedrohlc/.persistent zroot/data/my-files
zfs create -o mountpoint=/home/pedrohlc/.ssh zroot/data/my-ssh
zfs create -o mountpoint=/home/pedrohlc/Downloads -o recordsize=16K zroot/data/btdownloads
zfs create -o mountpoint=/home/pedrohlc/Games zroot/games/home
zfs create -o mountpoint=/home/pedrohlc/Projects zroot/data/my-projects

# Pedro's encrypted directories
zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/home/pedrohlc/.encrypted zroot/data/encrypted
zfs create -o encryption=on -o keyformat=passphrase \
	-o mountpoint=/home/pedrohlc/.mozilla zroot/data/mozilla

# Guests' homes
zfs create -o mountpoint=/home/melinapn zroot/guests/melinapn


echo 'Finished. After installing NixOS, change every mountpoint to legacy.'
