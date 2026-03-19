#!/usr/bin/env sh
set -euo pipefail

nix-store --gc --print-roots |\
  awk '{
    if (match($0, /^"([^"]*\/(result(-[a-z0-9]+|)?|flake-profile-.+-link))"/, m))
      printf "%s\0", m[1]
  }' |\
  xargs -0 --no-run-if-empty rm

nix-collect-garbage "$@"

exec /run/current-system/bin/switch-to-configuration boot --install-bootloader
