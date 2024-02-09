#!/usr/bin/env sh
set -eu

[ "${1:-}" == '--' ] && shift 1
[ "${1:-}" == 'steam' ] && shift 1
[ "${1:-}" == '-tenfoot' ] && shift 1

MANGOAPP=${MANGOAPP:-$(which mangoapp)}
STEAM=${STEAM:-$(which steam)}

"$MANGOAPP" &
_MANGO_APP_PID=$!

cd "$HOME"
"$STEAM" -tenfoot "$@" || _EXIT=$?

echo "Killing mangoapp in ${_MANGO_APP_PID}"
kill "${_MANGO_APP_PID}"

exit "${_EXIT:-0}"
