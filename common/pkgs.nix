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
  config = extraConfig // {
    allowUnfree = extraConfig.allowUnfree or false;
    pedroWatermark = true;
    allowUnfreePredicate =
      if builtins.hasAttr "allowUnfreePredicate" extraConfig then
        (pkg: (extraConfig.allowUnfreePredicate pkg) || (builtins.elem (nixpkgs.lib.getName pkg) unfree))
      else
        (pkg: builtins.elem (nixpkgs.lib.getName pkg) unfree);
  };
  overlays = [ (import ../overlays/core.nix flakes) flakes.chaotic.overlays.cache-friendly ] ++ extraOverlays;
}
