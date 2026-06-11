{ system, flakes, extraConfig ? { }, extraOverlays ? [ ] }:
let
  unfree = [
    "castlabs-electron"
    "claude-code"
    "devilutionx"
    "google-chrome"
    "nvidia-x11"
    "postman"
    "slack"
    "SpaceCadetPinball"
    "steam"
    "steam-jupiter-unwrapped"
    "steam-unwrapped"
    "steamdeck-hw-theme"
    "unrar"
    "wpsoffice"
    "zoom"
  ];

  inherit (flakes) nixpkgs;
in
import nixpkgs {
  inherit system;
  config = {
    allowUnfree = false;
    pedroWatermark = true;
    allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfree;
  } // extraConfig;
  overlays = [ (import ../overlays/core.nix flakes) flakes.chaotic.overlays.cache-friendly ] ++ extraOverlays;
}
