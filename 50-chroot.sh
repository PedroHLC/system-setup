#!/usr/bin/env sh
set -o errexit
cd /mnt

arch-chroot . /usr/bin/bash <<EOF
#!/usr/bin/env sh
set -o errexit

locale-gen
hwclock --systohc
timedatectl set-ntp true

pacman-key --init
pacman-key --populate archlinux
# Sublime-Text
pacman-key --keyserver hkps://hkps.pool.sks-keyservers.net -r ADAE6AD28A8F901A
pacman-key --lsign-key 1EDDE2CDFC025D17F6DA9EC0ADAE6AD28A8F901A

groupmod -g 10 wheel
groupmod -g 100 users
useradd -Uu 1000 -m pedrohlc
usermod -aG users,wheel pedrohlc

curl 'https://builds.garudalinux.org/repos/chaotic-aur/keyring.pkg.tar.zst' -o /tmp/keyring.pkg.tar.zst
curl 'https://builds.garudalinux.org/repos/chaotic-aur/mirrorlist.pkg.tar.zst' -o /tmp/mirrorlist.pkg.tar.zst

sudo pacman -U /tmp/keyring.pkg.tar.zst /tmp/mirrorlist.pkg.tar.zst

pacman -Sy --noconfirm --needed powerpill

powerpill -Su --noconfirm --needed --overwrite /boot/\\* \
	base-devel multilib-devel arch-install-scripts git man{,-pages} \
	sudo paru networkmanager pipewire amd-ucode \
	linux-firmware linux-tkg-bmq-zen2{,-headers} dbus-broker \
	\
	zfs{-dkms,-utils} efibootmgr \
	ntfs-3g dosfstools mtools exfat-utils un{rar,zip} p7zip \
	gvfs-mtp android-udev-git sshfs usbutils \
	\
	dash fish libpam-google-authenticator mosh rsync aria2 tmux \
	neovim-drop-in openssh htop bridge-utils traceroute wget \
	android-sdk-platform-tools dnsmasq hostapd inetutils \
	networkmanager-openvpn nm-eduroam-ufscar ca-certificates-icp_br \
	\
	{,lib32-}mesa {,lib32-}libva{,-mesa-driver} {,lib32-}vulkan-{icd-loader,radeon} \
	\
	bluez{,-plugins,-utils} \
	pipewire-{alsa,pulse,jack} gst-plugin-pipewire libpipewire02 \
	\
	sway{,bg,idle,lock} grim slurp waybar breeze{,-gtk} vimix-icon-theme-git \
	mako wdisplays-git plasma-integration \
	wl-clipboard-x11 qt5-wayland xdg-desktop-portal{,-wlr-git} \
	sway-launcher-desktop \
	\
	alacritty nomacs pcmanfm-qt qbittorrent telegram-desktop xarchiver \
	firefox-wayland-hg firefox-ublock-origin \
	mpv audacious{,-plugins} gst-libav kodi-wayland spotify-dev youtube-dl-git \
	pavucontrol \
	\
	{,lib32-}faudio steam steam-native-runtime \
	wine{_gecko,-mono,-tkg-staging-fsync-git} winetricks-git dxvk-mingw-git \
	xf86-input-libinput proton-tkg-git {,lib32-}mangohud vkbasalt gamemode \
	\
	keybase kbfs qemu sublime-text vinagre scrcpy-git \
	editorconfig-core-c python-pynvim hunspell-{en_US,pt-br} \
	podman podman-compose-git crun trash-cli \
	\
	gdb ruby yarn python-pip \
	\
	gnu-free-fonts gnome-icon-theme \
	ttf-{fira-{code,mono,sans}} ttf-borg-sans-mono \
	ttf-{dejavu,droid,liberation,ubuntu-font-family,wps-fonts} \
	ttf-font-awesome-4 \
	adobe-source-han-sans-jp-fonts
	\
	chaotic-mirrorlist chaotic-keyring

chsh root -s /bin/dash
chsh pedrohlc -s /bin/dash

usermod -aG audio,kvm pedrohlc

chown pedrohlc:pedrohlc /home/pedrohlc/.mozilla /media/encrypted
chmod 700 ./home/pedrohlc/.mozilla ./media/encrypted

bootctl --path=/boot install
zgenhostid
EOF

arch-chroot . sh -c 'echo [ROOT] && passwd root && echo [PEDROHLC] && passwd pedrohlc'

echo 'Finished'
