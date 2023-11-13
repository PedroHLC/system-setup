#!/usr/bin/env sh
set -euo pipefail

nix-store --gc --print-roots |\
  awk '{ if($1 ~ /\/(result(-[a-z]+|)?|flake-profile-.+-link)$/) print $1 }' |\
  xargs --no-run-if-empty rm

exec nix-collect-garbage "$@"
