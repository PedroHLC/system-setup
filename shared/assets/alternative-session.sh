#!/usr/bin/env bash

OPTIONS="nixpkgs-steam-sdr
flatpak-steam-sdr
flatpak-heroic-sdr
tmux
fish
bash
poweroff"

OPTIONS_HDR=""
if lsmod | grep -wq "amdgpu"; then
  OPTIONS_HDR="nixpkgs-steam-hdr
flatpak-steam-hdr
flatpak-heroic-hdr
"
fi

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

while true; do
  _PRE=()
  case $(fzf <<<"${OPTIONS_HDR}${OPTIONS}") in
    nixpkgs-steam-sdr)
      gamescope --steam --disable-color-management -- steam -tenfoot -pipewire-dmabuf
      ;;
    nixpkgs-steam-hdr)
      DXVK_HDR=1 steam-gamescope
      ;;
    flatpak-steam-sdr)
      _PRE=(gamescope --steam --disable-color-management --)
      flatpak-steam
      ;;
    flatpak-steam-hdr)
      _PRE=(DXVK_HDR=1 gamescope --steam --hdr-enabled --)
      flatpak-steam
      ;;
    flatpak-heroic-sdr)
      _PRE=(gamescope --)
      flatpak-heroic
      ;;
    flatpak-heroic-hdr)
      _PRE=(DXVK_HDR=1 gamescope --hdr-enabled --)
      flatpak-heroic
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
  esac;
done
