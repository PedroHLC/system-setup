#!/usr/bin/env sh
exec ssh -t "$@" -- nix \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  --accept-flake-config \
  run --impure --refresh 'github:PedroHLC/system-setup#pedrohlc-hm_infect'
