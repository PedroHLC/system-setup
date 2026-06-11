{
  # Specific to my TV
  imports = [ ./hdr-display.nix ];
  programs.gamescope = {
    args = [
      "-r"
      "120"
      "--hdr-sdr-content-nits"
      "400"
      "--hdr-itm-enabled"
      "--hdr-itm-sdr-nits"
      "100"
      "--hdr-itm-target-nits"
      "1500"
    ];
    env = {
      DXVK_HDR = "1";
    };
  };
}
