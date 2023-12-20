#!/usr/bin/env sh
exec ssh "$@" -- nix \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  --accept-flake-config \
  run --impure 'github:PedroHLC/system-setup#pedrohlc-hm-infect'
