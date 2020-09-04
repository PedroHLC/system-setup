#!/usr/bin/env sh
set -o errexit
cd /mnt

sudo arch-chroot . /usr/bin/bash <<EOF
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
# Chaotic-AUR
pacman-key --keyserver keys.mozilla.org -r 3056513887B78AEB 8A9E14A07010F7E3
pacman-key --lsign-key 3056513887B78AEB
pacman-key --lsign-key 8A9E14A07010F7E3

groupmod -g 10 wheel
groupmod -g 100 users
useradd -Uu 1000 -m -g users -G wheel pedrohlc

pacman -Sy --noconfirm --needed --overwrite /boot/\\* \
	base-devel multilib-devel arch-install-scripts git man{,-pages} \
	sudo yay networkmanager pulseaudio-{alsa,bluetooth,jack} \
	linux-tkg-pds-broadwell{,-headers} dbus-broker \
	\
	zfs{-dkms,-utils} efibootmgr \
	ntfs-3g dosfstools mtools exfat-utils un{rar,zip} p7zip \
	gvfs-mtp android-udev-git sshfs usbutils \
	\
	dash fish libpam-google-authenticator mosh powerpill rsync aria2 tmux \
	neovim-{drop-in,plug} openssh htop bridge-utils traceroute wget \
	android-sdk-platform-tools dnsmasq hostapd inetutils \
	networkmanager-openvpn nm-eduroam-ufscar ca-certificates-icp_br \
	\
	{,lib32-}mesa {,lib32-}libva intel-media-driver {,lib32-}vulkan-icd-loader \
	{,lib32-}vulkan-intel intel-ucode \
	chaotic-nvidia-dev-dkms-tkg {,lib32-}chaotic-nvidia-dev-utils-tkg \
	bbswitch-dkms bumblebee {,lib32-}primus-vk-git \
	\
	bluez{,-plugins,-utils} \
	cadence jack2 jack_capture libffado \
	\
	sway{,bg,idle,lock} grim slurp waybar breeze{,-gtk} vimix-icon-theme-git \
	intelbacklight-git mako wdisplays-git plasma-integration \
	wl-clipboard-x11 qt5-wayland xdg-desktop-portal{,-wlr-git} \
	sway-launcher-desktop \
	\
	alacritty nomacs pcmanfm-qt qbittorrent telegram-desktop xarchiver \
	firefox-wayland-hg firefox-ublock-origin \
	wps-office{,-mui-pt-br} ttf-wps-fonts \
	wps-office-extension-portuguese-brazilian-dictionary \
	mpv audacious{,-plugins} gst-libav kodi-wayland spotify youtube-dl-git \
	pavucontrol \
	\
	{,lib32-}faudio steam steam-native-runtime \
	wine{_gecko,-mono,-tkg-staging-fsync-git} winetricks-git dxvk-mingw-git \
	xf86-input-libinput proton-tkg-git {,lib32-}mangohud vkbasalt gamemode \
	\
	keybase kbfs qemu sublime-text vinagre scrcpy-git \
	editorconfig-core-c python-pynvim hunspell-{en_US,pt-br} \
	podman podman-compose-git \
	\
	gdb ruby yarn python-pip \
	\
	gnu-free-fonts gnome-icon-theme \
	ttf-{fira-{code,mono,sans}} \
	ttf-{dejavu,droid,liberation,ubuntu-font-family,wps-fonts} \
	ttf-font-awesome-4 \
	adobe-source-han-sans-jp-fonts
	\
	chaoitc-mirrorlist

chsh root -s /bin/dash
chsh pedrohlc -s /bin/dash

usermod -aG audio,bumblebee,backlight,kvm pedrohlc

chown pedrohlc:users /home/pedrohlc/.mozilla /media/encrypted
chmod 700 ./home/pedrohlc/.mozilla ./media/encrypted

bootctl --path=/boot install
zgenhostid
EOF

sudo arch-chroot . sh -c 'echo [ROOT] && passwd root && echo [PEDROHLC] && passwd pedrohlc'

echo 'Finished'