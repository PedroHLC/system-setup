{
  # Allows HDR gaming.
  programs.steam.gamescopeSession.enable = true; # HDR can only be used with headless Gamescope right now...
  programs.gamescope = {
    args = [ "--hdr-enabled" ];
    env = {
      DXVK_HDR = "1";
    };
  };
}
