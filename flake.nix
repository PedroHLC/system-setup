# This is just a direct-conversion of my non-flakes-Nix and channels to flakes
{
  description = "PedroHLC's NixOS Flake";

  # My main channel and extra repositories
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-gaming.url = "github:fufexan/nix-gaming";

    # I use this inputs every once in a while
    #nur.url = "github:nix-community/NUR";
    #master.url = "github:NixOS/nixpkgs/master";
  };

  # My systems
  outputs = { self, nixpkgs, ... }@attrs: {
    nixosConfigurations = {
      "laptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ./configuration.nix
          ./laptop/hardware-configuration.nix
          ./laptop/configuration.nix
        ];
      };

      "desktop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ./configuration.nix
          ./desktop/hardware-configuration.nix
          ./desktop/configuration.nix
        ];
      };
    };
  };
}

