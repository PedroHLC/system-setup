{ pkgs, flakes, ... }:

{
  hm-infect_pedrohlc = pkgs.callPackage ./hm-infect {
    specialArgs = flakes.self.specialArgs;
  };
}
