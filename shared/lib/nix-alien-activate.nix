({ nix-alien, pkgs, ... }: {
  nixpkgs.overlays = [
    nix-alien.overlays.default
  ];
  environment.systemPackages = [
    pkgs.nix-alien
    pkgs.nix-index # not necessary, but recommended
    pkgs.nix-index-update
  ];
})
