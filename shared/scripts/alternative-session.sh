#!/usr/bin/env bash

# Check dependencies + reproducible
set -eu
BASH=${BASH:-$(which bash)}
FISH=${FISH:-$(which fish)}
FLATPAK=${FLATPAK:-$(which flatpak)}
FZF=${FZF:-$(which fzf)}
GAMESCOPE=${GAMESCOPE:-$(which gamescope)}
GAMESCOPE_NOWRAP=${GAMESCOPE_NOWRAP:-$(which gamescope)}
GREP=${GREP:-$(which grep)}
LSMOD=${LSMOD:-$(which lsmod)}
STEAM=${STEAM:-$(which steam)}
STEAM_GAMESCOPE=${STEAM_GAMESCOPE:-$(which steam-gamescope)}
SYSTEMCTL=${SYSTEMCTL:-$(which systemctl)}
TMUX=${TMUX:-$(which tmux)}
WPCTL=${WPCTL:-$(which wpctl)}

_PARENT_PATH="$PATH"
PATH=${COREUTILS:-$(dirname $(which env))}

function ext() {
  env PATH="$_PARENT_PATH" "${_PRE[@]}" "$@"
}
set +e

# Prepare FZF menu options
OPTIONS="nixpkgs-steam-sdr
flatpak-heroic-sdr
tmux
fish
bash
poweroff"
#flatpak-steam-sdr

OPTIONS_HDR=""
if "$LSMOD" | "$GREP" -wq "amdgpu"; then
  OPTIONS_HDR="nixpkgs-steam-hdr
flatpak-heroic-hdr
"
#flatpak-steam-hdr
fi

# Helper functions
function flatpak-steam() {
  _OVERRIDES=$("$FLATPAK" override --user --show com.valvesoftware.Steam)
  if [[ -z $_OVERRIDES ]]; then
    "$FLATPAK" override --user --filesystem=/mnt com.valvesoftware.Steam
  fi

  ext -u LD_PRELOAD "$FLATPAK" run com.valvesoftware.Steam -tenfoot -pipewire-dmabuf "${@}"
}

function "$FLATPAK"-heroic() {
  ext -u LD_PRELOAD "$FLATPAK" run com.heroicgameslauncher.hgl "${@}"
}

function raise-volume() {
  "$WPCTL" set-volume '@DEFAULT_SINK@' '100%' || true
}

# The menu and its actions
while true; do
  _PRE=()
  case $("$FZF" <<<"${OPTIONS_HDR}${OPTIONS}") in
    nixpkgs-steam-sdr)
      raise-volume
      ext "$GAMESCOPE_NOWRAP" --steam --disable-color-management -- steam -tenfoot -pipewire-dmabuf
      ;;
    nixpkgs-steam-hdr)
      raise-volume
      ext DXVK_HDR=1 "${STEAM_GAMESCOPE}"
      ;;
    flatpak-steam-sdr)
      raise-volume
      _PRE=("$GAMESCOPE_NOWRAP" --steam --disable-color-management --) \
        flatpak-steam
      ;;
    flatpak-steam-hdr)
      raise-volume
      _PRE=(DXVK_HDR=1 gamescope --steam --hdr-enabled --) \
        flatpak-steam
      ;;
    flatpak-heroic-sdr)
      raise-volume
      _PRE=("$GAMESCOPE_NOWRAP" --) \
        flatpak-heroic
      ;;
    flatpak-heroic-hdr)
      raise-volume
      _PRE=(DXVK_HDR=1 gamescope --hdr-enabled --) \
        flatpak-heroic
      ;;
    tmux)
      ext "$TMUX" -l
      ;;
    fish)
      ext "$FISH" -l
      ;;
    bash)
      # can't "-login" here, it will trigger .profile
      ext "$BASH"
      ;;
    poweroff)
      exec "$SYSTEMCTL" poweroff
      ;;
    *)
      break
      ;;
  esac;
done
