{ pkgs
, ssot
, inputs
, username ? "pedrohlc"
, homeDirectory ? "/home/${username}"
}: with inputs;

let
  hmConfig =
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = inputs.self.specialArgs;
      modules = [
        chaotic.homeManagerModules.default
        (import ./${username} { seat = null; })
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
