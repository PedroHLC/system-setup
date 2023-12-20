#!/usr/bin/env sh
exec ssh "$@" -- nix --impure \
  --extra-experimental-features nix-command \
  --extra-experimental-features flakes \
  --accept-flake-config \
  run 'github:PedroHLC/system-setup#pedrohlc-hm-infect'
