#!/usr/bin/env sh
set -o errexit
cd /mnt

# copy things
sudo cp -a /etc/ssh/* ./etc/ssh/
sudo chmod 700 /etc/NetworkManager/system-connections
sudo cp -a /etc/NetworkManager/system-connections/* ./etc/NetworkManager/system-connections/

# auto VPN
cat <<EOF | sudo tee ./etc/NetworkManager/dispatcher.d/vpn-up > /dev/null
#!/usr/bin/sh
nmcli connection up home-pedrohlc-self
EOF