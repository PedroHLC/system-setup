{ writeShellScriptBin, userFirefox ? firefox-wayland, firefox-wayland, zenity ? gnome.zenity, gnome, zfs }:
writeShellScriptBin "firefox-gate" ''
  set -o errexit

  FIREFOX="${userFirefox}/bin/firefox"
  ZENITY="${zenity}/bin/zenity"
  ZFS="${zfs}/bin/zfs"

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
