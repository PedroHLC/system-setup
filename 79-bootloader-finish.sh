#!/usr/bin/env sh
set -o errexit
cd /mnt

# Bootloader & its hook
sudo arch-chroot . /usr/bin/bash <<EOF
#!/usr/bin/env sh
set -o errexit

mkinitcpio -Pv
pacman -S --needed --noconfirm systemd-boot-pacman-hook
EOF

echo 'Finished'