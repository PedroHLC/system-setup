# This is just a direct-conversion of my non-flakes-Nix and channels to flakes
{
  description = "PedroHLC's NixOS Flake";

  # My main channel and extra repositories
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-gaming.url = "github:fufexan/nix-gaming";

    # home-manager for managing my users' home
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  # My systems
  outputs = { self, nixpkgs, home-manager, ... }@attrs: {
    nixosConfigurations = {
      "laptop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ./configuration.nix
          ./laptop/hardware-configuration.nix
          ./laptop/configuration.nix
          # home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.pedrohlc = (import ./home/pedrohlc.nix {
              touchpad = "2362:597:UNIW0001:00_093A:0255_Touchpad";
              displayBrightness = true;
              cpuSensor = "coretemp-isa-0000";
              battery = "BAT0";
            });
          }
        ];
      };

      "desktop" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [
          ./configuration.nix
          ./desktop/hardware-configuration.nix
          ./desktop/configuration.nix
          ./desktop/servers/wireguard.nix
          ./desktop/servers/nix-cache.nix
          # home-manager
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.users.pedrohlc = (import ./home/pedrohlc.nix {
              cpuSensor = "k10temp-pci-00c3";
              gpuSensor = "amdgpu-pci-0900";
            });
          }
        ];
      };
    };
  };
}

