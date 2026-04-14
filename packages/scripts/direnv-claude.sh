#!/usr/bin/env bash
# Workaround for Zed bug that clobbers direnv PATH

set -eu
export REAL_CLAUDE_CODE_EXECUTABLE=${REAL_CLAUDE_CODE_EXECUTABLE:-$(which claude)}
export DIRENV=${DIRENV:-$(which direnv)}

# Clear direnv tracking so it re-exports the full environment
unset DIRENV_WATCHES DIRENV_DIR DIRENV_DIFF
eval "$("$DIRENV" export bash 2>/dev/null)"

exec "$REAL_CLAUDE_CODE_EXECUTABLE" "$@"
