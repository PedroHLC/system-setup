#!/usr/bin/env sh
set -eu

EXPECTED=$1
PATH=$2
SALT="${3:-}"

CAT=$(which cat)
CUT=$(which cut)
PRINTF=$(which printf)
SHA256SUM=$(which sha256sum)

if [ -r "$PATH" ]; then
  CURRENT=$({ "$CAT" "$PATH"; "$PRINTF" '%s' "$SALT"; } | "$SHA256SUM" --binary | "$CUT" -d' ' -f1)
  [ "$CURRENT" = "$EXPECTED" ] && exit 0
fi

exit 1
