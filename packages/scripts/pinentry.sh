#!/usr/bin/env sh
set -eu

if [ "${PINENTRY_USER_DATA:-}" = "tui" ]; then
  exec "@PINENTRY@/bin/pinentry-curses" "$@"
else
  exec "@PINENTRY@/bin/pinentry" "$@"
fi
