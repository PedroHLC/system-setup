{ lib, pkgs, config, ... }:

lib.mkIf (!config.focusMode) {
  environment.systemPackages = with pkgs; [
    # Social
    telegram-desktop_git
    tuba
    vesktop

    # Gaming
    bigsteam
    mangoapprun
    mangohud_git
    mesa-demos
    vulkan-caps-viewer
    vulkan-tools
    winetricks
    gamescope-wsi_git
    gamescope-wsi32_git

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

  # My special gamescope
  programs.gamescope = {
    enable = true;
    capSysNice = true;
    env = lib.mkForce {
      # I set DXVK_HDR in the alternative-sessions script.
      ENABLE_GAMESCOPE_WSI = "1";
    };
    package = pkgs.gamescope_git;
  };
  security.wrappers.valve-gamescope = {
    owner = "root";
    group = "root";
    source = "${pkgs.gamescope_git}/bin/gamescope";
    capabilities = "cap_sys_nice+pie";
  };
  environment.variables.GAMESCOPE_NOWRAP = "${config.security.wrapperDir}/valve-gamescope";
  fileSystems."/opt/gamescope" = {
    device = pkgs.gamescope_git.outPath;
    fsType = "none";
    options = [ "bind" "ro" "x-gvfs-hide" ];
  };

  # Both work and hobby projects
  environment.persistence."/var/persistent".users.pedrohlc.directories = [
    "Projects"
  ];
}
