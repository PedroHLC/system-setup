#!/usr/bin/env sh
set -o errexit
cd /mnt

# Bootloader
sudo arch-chroot . mkinitcpio -Pv

# Hooks
sudo pacman -S systemd-boot-pacman-hook

echo 'Finished'