{ pkgs
, specialArgs
, specs ? { seat = null; }
, username ? "pedrohlc"
, homeDirectory ? "/home/${username}"
}: with inputs;

let
  hmConfig =
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = specialArgs;
      modules = [
        chaotic.homeManagerModules.default
        (import ../../home/configurations/${username} specs)
        { home = { inherit username homeDirectory; }; }
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
