#!/usr/bin/env bash
set -o errexit

FIREFOX=${FIREFOX:-$(which firefox)}
ZENITY=${ZENITY:-$(which zenity)}
ZFS=${ZFS:-$(which zfs)}

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
