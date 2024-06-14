{ ssot, flakes, mkNixOS, ... }:

mkNixOS {
  system = "x86_64-linux";
  specs = ./specs.nix;
  extraModules = [
    flakes.impermanence.nixosModules.impermanence
    ../../modules/configs/4k-nohidpi.nix
    ../../modules/configs/journal-upload.nix
    ../../modules/configs/wireguard-client.nix
    ../../modules/configs/wgcf-teams.nix
    ../../modules/focus.nix
    ../../modules/configs/seat.nix
    ./hardware-configuration.nix
    ./configuration.nix
  ];
}
