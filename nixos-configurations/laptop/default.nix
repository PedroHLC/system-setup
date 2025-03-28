{ ssot, flakes, mkNixOS, ... }:

mkNixOS {
  system = "x86_64-linux";
  specs = ./specs.nix;
  extraModules = [
    flakes.impermanence.nixosModules.impermanence
    ../../nixos-modules/wireguard-client.nix
    ../../nixos-modules/wgcf-teams.nix
    ../../nixos-modules/anti-procrastination
    ../../nixos-modules/seat.nix
    ./hardware-configuration.nix
    ./configuration.nix
  ];
}
