#!/usr/bin/env sh
set -o errexit
cd /mnt

# migrate important files
#sudo cp -a /etc/ssh/* ./etc/ssh/
#sudo chmod 700 /etc/NetworkManager/system-connections
#sudo cp -a /etc/NetworkManager/system-connections/* ./etc/NetworkManager/system-connections/
#cp -av ~/* ./home/pedrohlc

# if just flashing another bootfs, remove future mountpoints
#sudo rm -rf ./home ./etc/ssh ./etc/NetworkManager/system-connections ./usr/local

# auto VPN
cat <<EOF | sudo tee ./etc/NetworkManager/dispatcher.d/vpn-up > /dev/null
#!/usr/bin/sh
nmcli connection up home-pedrohlc-self
EOF

arch-chroot -u pedrohlc:users curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo 'Finished'