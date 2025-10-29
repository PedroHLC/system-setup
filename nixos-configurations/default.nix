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
          inherit system extraConfig extraOverlays;
          inherit (flakes) nixpkgs chaotic;
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
          disabledModules = [ "hardware/facter/system.nix" ]; # due to nixosModules.readOnlyPkgs
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
