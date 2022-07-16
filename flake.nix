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

  outputs = { self, nixpkgs, home-manager, ... }@attrs: {
    # Defines a formatter for "nix fmt"
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    # My systems
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
            home-manager.users.pedrohlc = (import ./home/pedrohlc.nix {
              battery = "BAT0";
              cpuSensor = "coretemp-isa-0000";
              displayBrightness = true;
              gitKey = "F5BFC029DA9A28CE";
              nvidiaPrime = true;
              touchpad = "2362:597:UNIW0001:00_093A:0255_Touchpad";
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
            home-manager.users.pedrohlc = (import ./home/pedrohlc.nix {
              cpuSensor = "k10temp-pci-00c3";
              dangerousAlone = false;
              gitKey = "DF4C6898CBDC6DF5";
              gpuSensor = "amdgpu-pci-0900";
            });
          }
        ];
      };

      "vps-lab" = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
          ./vps-lab/oci-options.nix
          ./vps-lab/oci-common.nix
          ./vps-lab/configuration.nix
        ];
      };
    };
  };
}

