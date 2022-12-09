({ nix-alien, nix-ld, pkgs, ... }: {
  nixpkgs.overlays = [
    nix-alien.overlays.default
  ];
  imports = [
    # Optional, but this is needed for `nix-alien-ld` command
    nix-ld.nixosModules.nix-ld
  ];
  environment.systemPackages = [
    pkgs.nix-alien
    pkgs.nix-index # not necessary, but recommended
    pkgs.nix-index-update
  ];
})
