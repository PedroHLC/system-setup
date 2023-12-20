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
        {
          nix = {
            package = pkgs.nix;
            extraOptions = ''
              experimental-features = nix-command flakes
            '';

            # Always uses system's flakes instead of downloading or updating.
            registry = {
              nixpkgs.flake = inputs.nixpkgs;
              chaotic.flake = inputs.chaotic;
            };
          };

          home = {
            inherit username homeDirectory;
            stateVersion = "23.11";
          };

          # save some space
          manual.manpages.enable = false;
        }
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
