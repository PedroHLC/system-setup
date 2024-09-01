#!/usr/bin/env sh
set -eu

MANGOAPP=${MANGOAPP:-$(which mangoapp)}
GAMEMODERUN=${GAMEMODERUN:-$(which gamemoderun)}

"$MANGOAPP" &
_MANGO_APP_PID=$!

cd "$HOME"
"$GAMEMODERUN" "$@" || _EXIT=$?

echo "Killing mangoapp in ${_MANGO_APP_PID}"
kill "${_MANGO_APP_PID}"

exit "${_EXIT:-0}"
