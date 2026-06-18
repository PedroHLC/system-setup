#!/usr/bin/env bash
# notify <title> [sound]  — body read from stdin. Sends macOS banner + Moshi push.
#   sound: Glass (default, success), Basso (failure), or any macOS system sound name
set -euo pipefail

title="${1:?title required as first argument}"
sound="${2:-Glass}"
message=$(cat)

jq -n \
      --rawfile token "$HOME/.secrets/moshi-push.token" \
      --arg    title   "$title" \
      --arg    message "$message" \
      '{token: ($token | rtrimstr("\n")), title: $title, message: $message}' \
  | curl -sS -X POST https://api.getmoshi.app/api/webhook \
      -H "Content-Type: application/json" \
      --data-binary @- \
  >/dev/null

exec osascript <<AS
display notification "$(printf '%s' "$message" | sed 's/["\\]/\\&/g')" with title "$(printf '%s' "$title" | sed 's/["\\]/\\&/g')" sound name "$sound"
AS
