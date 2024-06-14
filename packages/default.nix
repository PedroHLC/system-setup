{ pkgs, flakes, ... }:

{
  hm-infect_pedrohlc = pkgs.callPackage {
    specialArgs = flakes.self.specialArgs;
  };
}
