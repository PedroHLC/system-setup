{ pkgs
, ssot
, inputs
, username ? "pedrohlc"
, homeDirectory ? "/home/${username}"
}: with inputs;

let
  hmConfig =
    home-manager.lib.homeManagerConfiguration {
      modules = [
        {
          nix.package = pkgs.nix;
          home = {
            stateVersion = "23.11";
            inherit username homeDirectory;
          };
        }
        chaotic.homeManagerModules.default
        (import ./${username} { seat = null; })
      ];
      inherit pkgs;
      extraSpecialArgs = inputs.self.specialArgs;
    };
in
hmConfig.activationPackage.overrideAttrs (prevAttrs: {
  passthru = (prevAttrs.passthru or { }) // { inherit hmConfig; };
})
