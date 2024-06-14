{ lib, pkgs, config, ... }:

lib.mkIf (!config.focusMode) {
  environment.systemPackages = with pkgs; [
    # Social
    telegram-desktop_git
    tuba
    vesktop

    # Gaming
    bigsteam
    mangohud_git
    mesa-demos
    vulkan-caps-viewer
    vulkan-tools
    winetricks

    #devilutionx
    #duckstation
    #openmohaa_git
    #openrct2
    #vcmi
  ];

  # Special apps (requires more than their package to work).
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true; # Gamescope session is better for AAA gaming.
      args = [ "--immediate-flips" "--" "bigsteam" ];
    };
  };
  programs.gamescope = {
    enable = true;
    capSysNice = false; # capSysNice freezes gamescopeSession for me.
    args = [ ];
    env = lib.mkForce {
      # I set DXVK_HDR in the alternative-sessions script.
      ENABLE_GAMESCOPE_WSI = "1";
    };
    package = pkgs.gamescope_git;
  };

  # Both work and hobby projects
  environment.persistence."/var/persistent".users.pedrohlc.directories = [
    "Projects"
  ];
}
