# Decent 4K display with no HiDPI scaling
{ pkgs, ... }:
{
  fonts.fontconfig = {
    antialias = true;
    subpixel = {
      rgba = "none";
      lcdfilter = "none";
    };
  };
}
