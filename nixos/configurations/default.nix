{ ssot, flakes, ... }@inputs:
let
  mkNixOS = { system, specs, extraModules ? [ ], specialArgs ? { } }: with flakes;
    let
      joinedSpecialArgs = self.specialArgs // { specs = import specs; } // specialArgs;
    in
    nixpkgs.lib.nixosSystem ({
      inherit system;

      specialArgs = joinedSpecialArgs;

      modules = [
        chaotic.nixosModules.default
        home-manager.nixosModules.home-manager
        lix-module.nixosModules.default
        ../modules/configs/core.nix
        { home-manager.users.pedrohlc = import ../../home/configurations/pedrohlc; }
      ] ++ extraModules;
    });


  params = inputs // { inherit mkNixOS; };
in
{
  "${ssot.vpn.lab.hostname}" = import ./vps-lab params;
  "${ssot.vpn.desktop.hostname}" = import ./desktop params;
  "${ssot.vpn.laptop.hostname}" = import ./laptop params;
}
