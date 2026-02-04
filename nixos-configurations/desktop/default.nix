{ ssot, flakes, mkNixOS, ... }:

mkNixOS {
  system = "x86_64-linux";
  specs = ./specs.nix;
  extraModules = [
    flakes.impermanence.nixosModules.impermanence
    ../../nixos-modules/4k-nohidpi.nix
    ../../nixos-modules/journal-upload.nix
    ../../nixos-modules/wireguard-client.nix
    ../../nixos-modules/wgcf-teams.nix
    ../../nixos-modules/seat.nix
    ../../nixos-modules/zfs-impermanence-on-shutdown.nix
    ./hardware-configuration.nix
    ./configuration.nix
  ];
  extraOverlays = [
    (import ../../overlays/seat.nix)
  ];
}
