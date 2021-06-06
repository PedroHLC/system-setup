#!/usr/bin/env sh
set -o errexit
cd /mnt

# makepkg
cat <<EOF | sed -i'' -e "/'protocol::agent'/,/# Other common tools:/{//!d};/'protocol::agent'/r /dev/stdin" ./etc/makepkg.conf > /dev/null
DLAGENTS=('ftp::/usr/bin/aria2c -UWget -s8 %u -o %o --max-connection-per-server=8 --min-split-size=1M'
          'http::/usr/bin/aria2c -UWget -s8 %u -o %o --max-connection-per-server=8 --min-split-size=1M'
          'https::/usr/bin/aria2c -UWget -s8 %u -o %o --max-connection-per-server=8 --min-split-size=1M'
          'rsync::/usr/bin/rsync -z %u %o'
          'scp::/usr/bin/scp -C %u %o')

EOF

# powepill
sed -i'' "
	s/\"--max-concurrent-downloads=[^\"]*\"/\"--max-concurrent-downloads=800\"/g;
	s/\"--max-connection-per-server=[^\"]*\"/\"--max-connection-per-server=16\"/g;
	s/\"--min-split-size=[^\"]*\"/\"--min-split-size=2M\"/g;
" ./etc/powerpill/powerpill.json

# services
systemctl --root=. enable dbus-broker
systemctl --root=. --global enable dbus-broker
systemctl --root=. enable NetworkManager
systemctl --root=. enable zfs-import-cache zfs-import.target
systemctl --root=. enable zfs.target zfs-mount # better than fstab
#systemctl --root=. enable sshd

# Why Lennart, why? (boost startup)
systemctl --root=. mask systemd-hostnamed

# disable LVM (boost startup)
sed -i'' 's/use_lvmetad = 1/use_lvmetad = 0/g' ./etc/lvm/lvm.conf
systemctl --root=. mask lvm2-{activation{,-early},lvmetad{,.socket},lvmpolld{,.socket},monitor} systemd-udev-settle

# create main user
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | tee -a ./etc/sudoers > /dev/null

# autologin
mkdir -p ./etc/systemd/system/getty@tty1.service.d/
cat <<EOF | tee ./etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin pedrohlc --noclear %I \$TERM
Type=simple
EOF


# google auth
sed -i'' -e '3i auth required pam_google_authenticator.so' /etc/pam.d/sshd

echo 'Finished'