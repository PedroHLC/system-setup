#!/usr/bin/env bash

read -r -d '' OPTIONS <<EOF
nixpkgs-steam-hdr
nixpkgs-steam-sdr
flatpak-steam-hdr
flatpak-steam-sdr
flatpak-heroic-hdr
flatpak-heroic-sdr
tmux
fish
bash
poweroff
EOF

function flatpak-steam() {
  _OVERRIDES=$(flatpak override --user --show com.valvesoftware.Steam)
  if [[ -z $_OVERRIDES ]]; then
    flatpak override --user --filesystem=/mnt com.valvesoftware.Steam
  fi

  env -u LD_PRELOAD "${_PRE[@]}" flatpak run com.valvesoftware.Steam -tenfoot -pipewire-dmabuf "${@}"
}

function flatpak-heroic() {
  env -u LD_PRELOAD "${_PRE[@]}" flatpak run com.heroicgameslauncher.hgl "${@}"
}

while true; do case $(fzf <<<"$OPTIONS") in
  nixpkgs-steam-sdr)
    gamescope --steam -- steam -tenfoot -pipewire-dmabuf
    ;;
  nixpkgs-steam-hdr)
    steam-gamescope
    ;;
  flatpak-steam-sdr)
    _PRE=(gamescope --steam) flatpak-steam
    ;;
  flatpak-steam-hdr)
    _PRE=(gamescope --steam --hdr-enabled) flatpak-steam
    ;;
  flatpak-heroic-sdr)
    _PRE=(gamescope) flatpak-heroic
    ;;
  flatpak-heroic-hdr)
    _PRE=(gamescope --hdr-enabled) flatpak-heroic
    ;;
  tmux)
    tmux -l
    ;;
  fish)
    fish -l
    ;;
  bash)
    bash -l
    ;;
  poweroff)
    exec systemctl poweroff
    ;;
  *)
    break
    ;;
esac; done
