{ ssot, flakes, mkNixOS, ... }:

mkNixOS {
  system = "x86_64-linux";
  specs = ./specs.nix;
  extraModules = [
    flakes.impermanence.nixosModules.impermanence
    ../../nixos-modules/4k-nohidpi.nix
    ../../nixos-modules/amdcpu.nix
    ../../nixos-modules/amdgpu.nix
    ../../nixos-modules/ctrl-near-space-key.nix
    ../../nixos-modules/focusrite-hifi.nix
    ../../nixos-modules/journal-upload.nix
    ../../nixos-modules/jovian.nix
    ../../nixos-modules/local-ai.nix
    ../../nixos-modules/monitor-follow-usb.nix
    ../../nixos-modules/pw-hifi.nix
    ../../nixos-modules/seat.nix
    ../../nixos-modules/tv-display.nix
    ../../nixos-modules/wgcf-teams.nix
    ../../nixos-modules/wireguard-client.nix
    ./configuration.nix
    ./hardware-configuration.nix
  ];
  extraOverlays = [
    (import ../../overlays/seat.nix)
    (import "${flakes.jovian}/overlay.nix")
  ];
}
