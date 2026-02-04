{ flakes, ... }@specialArgs: with flakes;
{
  "pedrohlc-at-foreign" = home-manager.lib.homeManagerConfiguration {
    pkgs = import ../common/pkgs.nix
      {
        inherit (flakes) nixpkgs;
        system = "aarch64-darwin";
      };
    extraSpecialArgs = specialArgs // { specs = import ./foreign/specs.nix; };
    modules = [
      { home = { username = "pedrohlc"; homeDirectory = "/Users/pedrohlc"; }; }
      ./pedrohlc
      ./foreign
    ];
  };
}
