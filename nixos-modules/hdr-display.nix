{
  # Allows HDR gaming.
  programs.gamescope = {
    args = [ "--hdr-enabled" ];
    env = {
      DXVK_HDR = "1";
    };
  };
}
