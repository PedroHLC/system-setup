{ ssot, flakes, ... }@inputs: with ssot;
let
  mkNixOS = { system, specs, extraModules ? [ ], specialArgs ? { }, extraOverlays ? [ ], extraConfig ? { } }: with flakes;
    let
      joinedSpecialArgs = self.specialArgs // { specs = import specs; } // specialArgs;
    in
    nixpkgs.lib.nixosSystem ({
      # Sets pkgs just once due to nixosModules.readOnlyPkgs
      pkgs = import ../common/pkgs.nix
        {
          inherit system flakes extraConfig extraOverlays;
        };

      specialArgs = joinedSpecialArgs;

      modules = [
        nixpkgs.nixosModules.readOnlyPkgs
        home-manager.nixosModules.home-manager
        nyx-loner.nixosModules.default
        ../nixos-modules/core.nix
        {
          home-manager.users.pedrohlc = import ../home-configurations/pedrohlc;
          # due to nixosModules.readOnlyPkgs
          disabledModules = [ "hardware/facter/system.nix" ];
          chaotic.nyx.overlay.enable = false;
        }
      ] ++ extraModules;
    });


  params = inputs // { inherit mkNixOS; };
in
{
  "${machines.lab.hostname}" = import ./vps-lab params;
  "${machines.desktop.hostname}" = import ./desktop params;
  "${machines.xbox.hostname}" = import ./xbox params;
}
