{ system, nixpkgs, chaotic, extraConfig ? { }, extraOverlays ? [ ] }:
let
  unfree = [
    "castlabs-electron"
    "devilutionx"
    "google-chrome"
    "nvidia-x11"
    "slack"
    "SpaceCadetPinball"
    "steam"
    "steam-unwrapped"
    "unrar"
    "wpsoffice"
    "zoom"
  ];
in
import nixpkgs {
  inherit system;
  config = {
    allowUnfree = false;
    pedroWatermark = true;
    allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) unfree;
  } // extraConfig;
  overlays = [ (import ../overlays/core.nix) chaotic.overlays.default ] ++ extraOverlays;
}
