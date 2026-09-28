{ flakes, config, lib, ... }:
{
  imports = [ "${flakes.jovian}/modules/steam" ];
  jovian.steam = {
    enable = true;
    autoStart = true;
    user = "pedrohlc";
    desktopSession = "sway";
    environment = {
      "STEAM_EXTRA_COMPAT_TOOLS_PATHS" = lib.makeSearchPathOutput "steamcompattool" "" config.programs.steam.extraCompatPackages;
    };
  };
  programs.gamescope.enable = lib.mkForce false;
}
