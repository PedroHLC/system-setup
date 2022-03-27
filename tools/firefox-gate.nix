pkgs: pkgs.writeShellScriptBin "firefox-gate" ''
  set -o errexit

  FIREFOX="${pkgs.firefox-wayland}/bin/firefox"
  ZENITY="${pkgs.gnome.zenity}/bin/zenity"
  ZFS="${pkgs.zfs}/bin/zfs"

  echo 'Handling encrypted .mozilla'
  if [ "$USER" != 'pedrohlc' ] || [ -f "$HOME/.mozilla/firefox/profiles.ini" ]; then
    exec "$FIREFOX" "$@"
  else
    "$ZENITY" --password | sudo "$ZFS" load-key zroot/data/mozilla
    sudo "$ZFS" mount zroot/data/mozilla

    "$FIREFOX" "$@"

    sudo "$ZFS" umount -f zroot/data/mozilla
    sudo "$ZFS" unload-key zroot/data/mozilla
  fi
''
