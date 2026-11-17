#!/usr/bin/env bash
set -euo pipefail

function attempt() {
  dest=$1
  current=$(ddcutil getvcp 60 --noverify --brief)

  if [[ "$current" != *"${dest#0}" ]]; then
    echo "Needed to try again (current: $current)"
    ddcutil setvcp 60 "$dest" --noverify || true

    return 0
  fi

  return 23
}

if attempt "$@"; then
  sleep 3
  attempt "$@" || true
fi

exit 0
