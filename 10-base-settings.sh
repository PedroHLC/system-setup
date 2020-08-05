#!/usr/bin/env sh
set -o errexit
cd /mnt

# set locale
pushd ./etc
sudo rm localtime || echo 'There was no localtime'
sudo ln -s ../usr/share/zoneinfo/America/Sao_Paulo ./localtime
popd

echo 'en_US.UTF-8 UTF-8' | sudo tee -a ./etc/locale.gen > /dev/null
echo 'pt_BR.UTF-8 UTF-8' | sudo tee -a ./etc/locale.gen > /dev/null

echo 'LANG=en_US.UTF-8' | sudo cp /dev/stdin ./etc/locale.conf
echo 'KEYMAP=br-abnt2' | sudo cp /dev/stdin ./etc/vconsole.conf
sudo chmod 644 ./etc/locale.conf

# set hostname and hosts
echo 'pc' | sudo cp /dev/stdin ./etc/hostname

cat <<EOF | sudo tee -a ./etc/hosts > /dev/null
127.0.0.1 localhost
::1 localhost
127.0.1.1 pc.localdomain pc
EOF

# add some servers
cat <<EOF | sudo tee ./etc/pacman.d/mirrorlist > /dev/null
Server = http://mirror.ufscar.br/archlinux/\$repo/os/\$arch
Server = http://br.mirror.archlinux-br.org/\$repo/os/\$arch
Server = http://archlinux.c3sl.ufpr.br/\$repo/os/\$arch
Server = http://www.caco.ic.unicamp.br/archlinux/\$repo/os/\$arch
Server = https://www.caco.ic.unicamp.br/archlinux/\$repo/os/\$arch
Server = http://linorg.usp.br/archlinux/\$repo/os/\$arch
Server = http://pet.inf.ufsc.br/mirrors/archlinux/\$repo/os/\$arch
Server = http://archlinux.pop-es.rnp.br/\$repo/os/\$arch
Server = http://mirror.ufam.edu.br/archlinux/\$repo/os/\$arch
EOF

# add custom repo
cat <<EOF | sudo tee -a ./etc/pacman.conf > /dev/null

[multilib]
Include = /etc/pacman.d/mirrorlist

[chaotic-aur]
Server = https://lonewolf.pedrohlc.com/\$repo/\$arch
Server = http://chaotic.bangl.de/\$repo/\$arch

[sublime-text]
Server = https://download.sublimetext.com/arch/stable/\$arch
EOF

echo 'Finished'