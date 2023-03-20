# Decent 4K display with no HiDPI
{ pkgs, ... }:
{
  hardware.video.hidpi.enable = false;
  fonts.fontconfig = {
    antialias = true;
    subpixel = {
      rgba = "none";
      lcdfilter = "none";
    };
  };
}
