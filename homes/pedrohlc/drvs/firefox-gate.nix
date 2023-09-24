{ writeShellScriptBin, userFirefox ? firefox_nightly, firefox_nightly, zenity ? gnome.zenity, gnome, zfs }:
# This is a wrapper to run firefox with a zfs-encrypted profile, requires sudo
writeShellScriptBin "firefox-gate" ''
  set -o errexit

  FIREFOX="${userFirefox}/bin/firefox"
  ZENITY="${zenity}/bin/zenity"
  ZFS="${zfs}/bin/zfs"

  echo 'Handling encrypted .mozilla'
  if [ "$USER" != 'pedrohlc' ] || [ -f "$HOME/.mozilla/firefox/profiles.ini" ]; then
    exec "$FIREFOX" "$@"
  else
    "$ZENITY" --title=firefox-gate --password |\
      (sudo "$ZFS" load-key zroot/data/mozilla \
      || ("$ZENITY" --title=firefox-gate --error --text='Unable to load-key' && false) \
      )
    sudo "$ZFS" mount zroot/data/mozilla \
      || ("$ZENITY" --title=firefox-gate --error --text='Unable to mount' && false)

    "$FIREFOX" "$@"

    sudo "$ZFS" umount -f zroot/data/mozilla
    sudo "$ZFS" unload-key zroot/data/mozilla
  fi
''
