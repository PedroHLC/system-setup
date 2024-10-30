{ pkgs
, specialArgs
, specs ? { seat = null; }
, username ? "pedrohlc"
, homeDirectory ? "/home/${username}"
}: with specialArgs.flakes;

let
  hmConfig =
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = specialArgs // { inherit specs; };
      modules = [
        chaotic.homeManagerModules.default
        { home = { inherit username homeDirectory; }; }
        ../../home/configurations/${username}
        ./non-nixos.nix
      ];
    };

  base =
    pkgs.writeShellScriptBin "activate" ''
      set -xe
      ${hmConfig.activationPackage}/activate
      exec sh -l
    '';
in
base.overrideAttrs (prevAttrs: {
  passthru = (prevAttrs.passthru or { }) // { inherit hmConfig; };
})
