# This is just a direct-conversion of my non-flakes-Nix and channels to flakes
{
  description = "PedroHLC's NixOS Flake";

  # My main channel and extra repositories
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # reset rootfs every reboot
    impermanence.url = "github:nix-community/impermanence";

    # home-manager for managing my users' home
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Smooth-criminal bleeding-edge packages
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    # My FFx userChrome.css
    pedrochrome-css = {
      url = "git+https://gist.github.com/3c52f40134eeadf689d6269f271c755b.git";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, impermanence, chaotic, ... }@inputs:
    let
      ssot = import ./shared/ssot.nix inputs;
      specialArgs = {
        inherit ssot;
        flakes = inputs;
      };
      homeManagerModules = specsFile:
        let
          specs = (import specsFile);
          pedrohlc = import ./homes/pedrohlc specs;
        in
        [
          home-manager.nixosModules.home-manager
          { home-manager.users = { inherit pedrohlc; }; }
        ];
      commonModules =
        [
          chaotic.nixosModules.default
          ./systems/core-configuration.nix
        ];
    in
    {
      # Defines a formatter for "nix fmt"
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      # My systems
      nixosConfigurations = {
        "${ssot.vpn.laptop.hostname}" = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          modules = commonModules ++ [
            impermanence.nixosModules.impermanence
            ./shared/config/wireguard-client.nix
            ./shared/config/wgcf-teams.nix
            ./systems/seat-configuration.nix
            ./systems/laptop/hardware-configuration.nix
            ./systems/laptop/configuration.nix
          ] ++ (homeManagerModules ./systems/laptop/specs.nix);
        };

        "${ssot.vpn.desktop.hostname}" = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          modules = commonModules ++ [
            impermanence.nixosModules.impermanence
            ./shared/config/4k-nohidpi.nix
            ./shared/config/journal-upload.nix
            ./shared/config/wireguard-client.nix
            ./shared/config/wgcf-teams.nix
            ./systems/seat-configuration.nix
            ./systems/desktop/hardware-configuration.nix
            ./systems/desktop/configuration.nix
          ] ++ (homeManagerModules ./systems/desktop/specs.nix);
        };

        "${ssot.vpn.lab.hostname}" = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "aarch64-linux";
          modules = commonModules ++ [
            (nixpkgs + "/nixos/modules/profiles/qemu-guest.nix")
            ./shared/config/oci-options.nix
            ./shared/config/oci-common.nix
            ./systems/vps-lab/configuration.nix
            ./systems/vps-lab/servers/adguard.nix
            ./systems/vps-lab/servers/journal-remote.nix
            ./systems/vps-lab/servers/libreddit.nix
            ./systems/vps-lab/servers/nginx.nix
            ./systems/vps-lab/servers/wireguard.nix
            ./systems/vps-lab/services/mesa-mirror
          ] ++ (homeManagerModules ./systems/vps-lab/specs.nix);
        };
      };
    };
}

