utils: with utils;

mkIf hasSeat {
  # Cursor setup
  home.pointerCursor = {
    name = cursorTheme;
    package = pkgs.kdePackages.breeze;
    gtk.enable = true;
    size = cursorSize;
  };

  # GTK Setup
  gtk = {
    enable = true;
    theme.name = "Breeze-Dark";
    iconTheme.name = iconTheme;
    cursorTheme = {
      size = cursorSize;
      name = cursorTheme;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };
  dconf.settings."org/gtk/settings/file-chooser" = {
    sort-directories-first = true;
  };

  # GTK4 Setup
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = mkForce "Breeze";
    color-scheme = "prefer-dark";
  };

  xdg.configFile = {
    # The entire qt module is useless for me as I use Breeze with Plasma's platform-theme.
    kdeglobals = {
      text = generators.toINI { } {
        General = {
          ColorScheme = "BreezeDark";
          Name = "Breeze Dark";
          shadeSortColumn = true;
        };
        Icons = {
          Theme = iconTheme;
        };
        KDE = {
          LookAndFeelPackage = "org.kde.breezedark.desktop";
          contrast = 4;
          widgetStyle = "Breeze";
        };
      };
    };
    kcminputrc = {
      text = generators.toINI { } {
        Mouse = { inherit cursorTheme cursorSize; };
      };
    };
  };
}
