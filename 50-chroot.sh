#!/usr/bin/env sh
set -o errexit
cd /mnt

sudo arch-chroot . /usr/bin/bash <<EOF
#!/usr/bin/env sh

locale-gen
hwclock --systohc
timedatectl set-ntp true

pacman-key --init
pacman-key --populate archlinux
# Sublime-Text
pacman-key --keyserver hkps://hkps.pool.sks-keyservers.net -r ADAE6AD28A8F901A
pacman-key --lsign-key 1EDDE2CDFC025D17F6DA9EC0ADAE6AD28A8F901A
# Chaotic-AUR
pacman-key --keyserver keys.mozilla.org -r 3056513887B78AEB
pacman-key --lsign-key 3056513887B78AEB
pacman -Syu --noconfirm

passwd root
chsh root /bin/dash

pacman -S linux-tkg-pds-broadwell{,-headers} --noconfirm
pacman -S --noconfirm --needed \
	base-devel multilib-devel arch-install-scripts git man{,-pages} \
	sudo yay networkmanager pulseaudio-{alsa,bluetooth,jack} \
	\
	zfs{-dkms,-utils} efibootmgr \
	ntfs-3g dosfstools mtools exfat-utils un{rar,zip} p7zip \
	gvfs-mtp android-udev-git sshfs usbutils wget aria2 \
	\
	dash fish libpam-google-authenticator mosh powerpill rsync aria2 tmux \
	neovim-{drop-in,plug} openssh htop bridge-utils alsa-utils traceroute nmap \
	android-sdk-platform-tools ddclient dnsmasq hostapd tor inetutils \
	networkmanager-openvpn nm-eduroam-ufscar ca-certificates-icp_br \
	\
	{,lib32-}mesa {,lib32-}libva-{mesa,intel}-driver {,lib32-}vulkan-icd-loader \
	{,lib32-}vulkan-intel intel-ucode \
	nvidia-dev-dkms-tkg {,lib32-}nvidia-dev-utils-tkg {,lib32-}primus-vk-git bbswitch-dkms bumblebee \
	mesa-vdpau libva-vdpau-driver \
	\
	bluez{,-plugins,-utils} cups sane \
	cadence jack2 jack_capture \
	\
	sway{,bg,idle,lock} grim waybar wofi-hg \
	intelbacklight-git menu-calc mako wdisplays-git lxappearance \
	wl-clipboard-x11 qt5-wayland xdg-desktop-portal{,-wlr-git} \
	\
	alacritty nomacs pcmanfm-qt qbittorrent telegram-desktop xarchiver \
	firefox-wayland-hg firefox-ublock-origin \
	wps-office{,-mui-pt-br} ttf-wps-fonts \
	wps-office-extension-portuguese-brazilian-dictionary \
	mpv audacious{,-plugins} gst-libav kodi-wayland spotify youtube-dl \
	gomics-git paprefs pavucontrol print-manager system-config-printer \
	\
	dxvk-mingw-git {,lib32-}faudio steam steam-native-runtime \
	wine{_gecko,-mono,-tkg-staging-fsync-git} \
	xf86-input-libinput \
	\
	keybase kbfs qemu sublime-text vinagre yeecli easy-rsa scrcpy-git \
	gdb dbeaver editorconfig-core-c python-{pip,pynvim} ruby hunspell-{en_US,pt-br} \
	\
	gnu-free-fonts otf-font-awesome gnome-icon-theme \
	ttf-{dejavu,droid,fira-{code,mono,sans},font-awesome-4} \
	ttf-{liberation,ms-fonts,ubuntu-font-family,wps-fonts}

groupmod -g 10 wheel
groupmod -g 100 users
useradd -u 1000 -m -G wheel -g users -s /bin/dash pedrohlc
passwd pedrohlc
usermod \
	-aG audio -aG video -aG input -aG kvm \
	-aG bumblebee -aG backlight \
	pedrohlc

chown pedrohlc:users /home/pedrohlc/.mozilla /media/encrypted
chmod 700 ./home/pedrohlc/.mozilla ./media/encrypted

bootctl --path=/boot install
zgenhostid
EOF