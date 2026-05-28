{ flakes, ... }@specialArgs: with flakes;
{
  "pedrohlc-at-foreign" = home-manager.lib.homeManagerConfiguration {
    pkgs = import ../common/pkgs.nix
      {
        inherit flakes;
        system = "aarch64-darwin";
      };
    extraSpecialArgs = specialArgs // { specs = import ./foreign/specs.nix; };
    modules = [
      chaotic.homeModules.default
      {
        home = { username = "pedrohlc"; homeDirectory = "/Users/pedrohlc"; };
        chaotic.nyx.overlay.enable = false;
      }
      ./pedrohlc
      ./foreign
    ];
  };
}
