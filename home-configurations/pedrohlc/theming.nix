utils: with utils;

{
  stylix.enable = isLinux;
  stylix.overlays.enable = false;

  stylix.base16Scheme = {
    # https://github.com/vic/base16-rebecca
    author = "vic";
    base00 = "292a44";
    base01 = "663399";
    base02 = "383a62";
    base03 = "666699";
    base04 = "a0a0c5";
    base05 = "f1eff8";
    base06 = "ccccff";
    base07 = "53495d";
    base08 = "a0a0c5";
    base09 = "efe4a1";
    base0A = "ae81ff";
    base0B = "6dfedf";
    base0C = "8eaee0";
    base0D = "2de0a7";
    base0E = "7aa5ff";
    base0F = "ff79c6";
    scheme = "Rebecca";
    slug = "rebecca";
  };
} //
(optionalAttrs hasLinuxSeat {
  stylix.fonts = {
    monospace = {
      name = "Borg Sans Mono";
      package = pkgs.borg-sans-mono;
    };
    sansSerif = {
      name = "Noto Sans";
      package = pkgs.noto-fonts;
    };
    serif = {
      name = "Noto Serif";
      package = pkgs.noto-fonts;
    };
    sizes = {
      applications = 11;
      desktop = 11;
    };
  };

  stylix.image = pkgs.fetchurl {
    url = privateBucket "Wallpapers/Aenami-Horizon.png";
    hash = "sha256-3yzQkPRTeYdWV6bAoNZWwiDugywtNrh73k5vGfsHMLw=";
  };

  stylix.polarity = "dark";

  stylix.cursor.size = 24;
  stylix.cursor = {
    name = "Breeze_Light";
    package = pkgs.kdePackages.breeze;
  };

  gtk.iconTheme = {
    name = iconTheme;
    package = pkgs.vimix-icon-theme;
  };

  # Plasma LookAndFeel for Sway
  wayland.windowManager.sway.config.startup = [
    { command = "plasma-apply-lookandfeel --apply stylix"; }
  ];
})
