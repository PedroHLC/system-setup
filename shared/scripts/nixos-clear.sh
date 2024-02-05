#!/usr/bin/env sh
set -euo pipefail

nix-store --gc --print-roots |\
  awk '{ if($1 ~ /\/(result(-[a-z]+|)?|flake-profile-.+-link)$/) print $1 }' |\
  xargs --no-run-if-empty rm

nix-collect-garbage "$@"

exec /run/current-system/bin/switch-to-configuration boot --install-bootloader
