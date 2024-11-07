#!/usr/bin/env bash
set -eu

BOOTCTL="${BOOTCTL:-$(which bootctl)}"
SYSTEMCTL="${SYSTEMCTL:-$(which systemctl)}"

entries='/boot/loader/entries'
generations=("$entries/nixos-generation"-*[0123456789].conf)
last_id="${generations[-1]#"$entries/"}"
last_base="${last_id%'.conf'}"

if [ -n "${1:-}" ]; then
  special="${last_base}${1}.conf"
  if [ ! -f "$entries/$special" ]; then
    echo "UNABLE TO FIND SPECIAL BOOT ENTRY" >&2
    exit 2
  fi
  "$BOOTCTL" set-oneshot "$special"
else
  "$BOOTCTL" set-oneshot "$last_id"
fi

if [[ "${REBOOT_NOW:-yes}" == "yes" ]]; then
    exec "$SYSTEMCTL" reboot
fi
