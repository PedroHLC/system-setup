{ ssot, flakes, ... }@inputs: with ssot;
let
  mkNixOS = { system, specs, extraModules ? [ ], specialArgs ? { }, extraOverlays ? [ ], extraConfig ? { } }: with flakes;
    let
      joinedSpecialArgs = self.specialArgs // { specs = import specs; } // specialArgs;
    in
    nixpkgs.lib.nixosSystem ({
      # Sets pkgs just once due to nixosModules.readOnlyPkgs
      pkgs = import flakes.nixpkgs {
        inherit system;
        config = {
          allowUnfree = false;
          pedroWatermark = true;
          allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) (import ../common/unfree.nix);
        } // extraConfig;
        overlays = [ (import ../overlays/core.nix) chaotic.overlays.default ] ++ extraOverlays;
      };

      specialArgs = joinedSpecialArgs;

      modules = [
        nixpkgs.nixosModules.readOnlyPkgs
        chaotic.nixosModules.default
        home-manager.nixosModules.home-manager
        ../nixos-modules/core.nix
        {
          home-manager.users.pedrohlc = import ../home-configurations/pedrohlc;
          chaotic.nyx.overlay.enable = false; # due to nixosModules.readOnlyPkgs
        }
      ] ++ extraModules;
    });


  params = inputs // { inherit mkNixOS; };
in
{
  "${machines.lab.hostname}" = import ./vps-lab params;
  "${machines.desktop.hostname}" = import ./desktop params;
  "${machines.laptop.hostname}" = import ./laptop params;
}
