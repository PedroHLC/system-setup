{ flakes, lib, ... }:
{
  imports = [ "${flakes.jovian}/modules/steam" ];
  jovian.steam = {
    enable = true;
    autoStart = true;
    user = "pedrohlc";
    desktopSession = "sway";
  };
  programs.gamescope.enable = lib.mkForce false;
}
