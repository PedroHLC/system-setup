# This is just a direct-conversion of my non-flakes-Nix and channels to flakes
{
  description = "PedroHLC's NixOS Flake";

  # My main channel and extra repositories
  inputs = {
    nixpkgs.url = "github:PedroHLC/nixpkgs/gamescope-hdr-rebased";

    # reset rootfs every reboot
    impermanence.url = "github:nix-community/impermanence";

    # home-manager for managing my users' home
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Smooth-criminal bleeding-edge Mesa3D
    mesa-git-src = {
      url = "github:chaotic-aur/mesa-mirror/main";
      flake = false;
    };

    # My FFx userChrome.css
    pedrochrome-css = {
      url = "git+https://gist.github.com/3c52f40134eeadf689d6269f271c755b.git";
      flake = false;
    };

    # Bleeding-edge Waynergy
    waynergy-git-src = {
      url = "github:r-c-f/waynergy/master";
      flake = false;
    };

    # Bleeding-edge input-leap
    input-leap-git-src = {
      url = "github:input-leap/input-leap/master";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, impermanence, ... }@inputs:
    let
      ssot = import ./shared/ssot.nix inputs;
      specialArgs = {
        inherit ssot;
        flakeInputs = inputs;
      };
    in
    {
      # Defines a formatter for "nix fmt"
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      # My systems
      nixosConfigurations = {
        "${ssot.vpn.laptop.hostname}" = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          modules = [
            impermanence.nixosModules.impermanence
            ./shared/lib/wireguard-client.nix
            ./shared/lib/zfs-impermanence-on-shutdown.nix
            ./systems/core-configuration.nix
            ./systems/seat-configuration.nix
            ./systems/laptop/hardware-configuration.nix
            ./systems/laptop/configuration.nix
            # home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.users.pedrohlc = import ./home-manager/pedrohlc.nix {
                battery = "BAT0";
                cpuSensor = "coretemp-isa-0000";
                displayBrightness = true;
                gitKey = "F5BFC029DA9A28CE";
                nvidiaPrime = true;
                # persistence = true;
                touchpad = "2362:597:UNIW0001:00_093A:0255_Touchpad";
              };
            }
          ];
        };

        "${ssot.vpn.desktop.hostname}" = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          modules = [
            impermanence.nixosModules.impermanence
            ./shared/lib/4k-nohidpi.nix
            ./shared/lib/graphics-stack-bleeding.nix
            ./shared/lib/journal-upload.nix
            ./shared/lib/wireguard-client.nix
            ./shared/lib/wgcf-teams.nix
            ./shared/lib/zfs-impermanence-on-shutdown.nix
            ./systems/core-configuration.nix
            ./systems/seat-configuration.nix
            ./systems/desktop/hardware-configuration.nix
            ./systems/desktop/configuration.nix
            # home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.users.pedrohlc = import ./home-manager/pedrohlc.nix {
                cpuSensor = "k10temp-pci-00c3";
                dangerousAlone = false;
                gitKey = "DF4C6898CBDC6DF5";
                gpuSensor = "amdgpu-pci-0900";
              };
            }
          ];
        };

        "${ssot.vpn.lab.hostname}" = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "aarch64-linux";
          modules = [
            (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
            ./shared/lib/oci-options.nix
            ./shared/lib/oci-common.nix
            ./systems/core-configuration.nix
            ./systems/vps-lab/configuration.nix
            ./systems/vps-lab/servers/adguard.nix
            ./systems/vps-lab/servers/journal-remote.nix
            ./systems/vps-lab/servers/libreddit.nix
            ./systems/vps-lab/servers/nginx.nix
            ./systems/vps-lab/servers/wireguard.nix
            ./systems/vps-lab/services/mesa-mirror
            # home-manager
            home-manager.nixosModules.home-manager
            {
              home-manager.users.pedrohlc = import ./home-manager/pedrohlc.nix {
                seat = false;
              };
            }
          ];
        };

      };
    };
}

