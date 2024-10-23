utils: with utils;
{
  xdg = {
    # Config files that I prefer to just specify
    configFile = {
      # Disable this thing that is included with KDE
      baloofilerc = mkIf hasSeat {
        text = generators.toINI { } {
          "Basic Settings" = {
            "Indexing-Enabled" = false;
          };
        };
      };
      # Allow me to choose which display to share in a list.
      wlrPortal = mkIf hasSeat {
        target = "xdg-desktop-portal-wlr/config";
        text = generators.toINI { } {
          screencast = {
            chooser_type = "dmenu";
            chooser_cmd = pseudoPkgs.output-chooser;
          };
        };
      };
      # Notifications
      swaync = {
        enable = hasSeat;
        target = "swaync/config.json";
        text = generators.toJSON { } {
          "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/configSchema.json";
          positionX = seat.notificationX;
          positionY = seat.notificationY;
        };
      };
      # Integrate the filemanager with the rest of the system
      pcmanfm = {
        enable = hasSeat;
        target = "pcmanfm-qt/default/settings.conf";
        text = generators.toINI { } {
          Behavior = {
            NoUsbTrash = true;
            SingleWindowMode = true;
          };
          System = {
            Archiver = "xarchiver";
            FallbackIconThemeName = iconTheme;
            Terminal = "${bin.terminal}";
            SuCommand = "${pkgs.lxqt.lxqt-sudo}/bin/lxqt-sudo %s";
          };
          Thumbnail = {
            ShowThumbnails = true;
          };
          Volume = {
            AutoRun = false;
            CloseOnUnmount = true;
            MountOnStartup = false;
            MountRemovable = false;
          };
        };
      };
      zed = {
        enable = hasSeat;
        target = "zed/settings.json";
        source = ../../../assets/zed-settings.json;
      };
    };
    # Other data files
    dataFile = {
      userChromeCss = {
        enable = hasSeat;
        target = "userChrome.css";
        source = "${flakes.pedrochrome-css}/userChrome.css";
      };
      zedNodeBin = {
        enable = hasSeat;
        target = "zed/node/node-v22.5.1-linux-x64/bin";
        source = "${pkgs.nodejs_22}/bin";
      };
      zedNodeLib = {
        enable = hasSeat;
        target = "zed/node/node-v22.5.1-linux-x64/lib";
        source = "${pkgs.nodejs_22}/lib";
      };
    };
    desktopEntries = mkIf hasSeat {
      # Overwrite Firefox with my encryption-wrapper
      "firefox${firefoxSuffix}" = {
        name = "Firefox (Wayland)";
        genericName = "Web Browser";
        exec = "${pseudoPkgs.firefox-gate}/bin/firefox-gate %U";
        terminal = false;
        categories = [ "Application" "Network" "WebBrowser" ];
        mimeType = [
          "application/pdf"
          "application/vnd.mozilla.xul+xml"
          "application/xhtml+xml"
          "text/html"
          "text/xml"
          "x-scheme-handler/ftp"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
        type = "Application";
      };
      "pokemmo" = {
        name = "PokeMMO";
        genericName = "MMORPG about leveling up and discovering new monsters";
        exec = "${pseudoPkgs.pokemmo-launcher}/bin/pokemmo";
        terminal = false;
        categories = [ "Game" ];
        type = "Application";
        icon = "${homePath}/Games/PokeMMO/data/icons/128x128.png";
      };
    };

    # Default apps per file type
    mimeApps = {
      enable = hasSeat;
      associations = {
        added = {
          "application/octet-stream" = "dev.zed.Zed.desktop";
        };
        removed = {
          "image/gif" = "google-chrome.desktop";
          "image/jpeg" = "google-chrome.desktop";
          "image/png" = "google-chrome.desktop";
          "image/webp" = "google-chrome.desktop";
        };
      };
      defaultApplications = {
        "image/gif" = "org.nomacs.ImageLounge.desktop";
        "image/jpeg" = "org.nomacs.ImageLounge.desktop";
        "image/png" = "org.nomacs.ImageLounge.desktop";
        "image/webp" = "org.nomacs.ImageLounge.desktop";
        "application/pdf" = "firefox.desktop";
        "inode/directory" = "pcmanfm-qt.desktop";

        "x-scheme-handler/http" = defaultBrowser;
        "x-scheme-handler/https" = defaultBrowser;
        "x-scheme-handler/chrome" = defaultBrowser;
        "text/html" = defaultBrowser;
        "application/x-extension-htm" = defaultBrowser;
        "application/x-extension-html" = defaultBrowser;
        "application/x-extension-shtml" = defaultBrowser;
        "application/xhtml+xml" = defaultBrowser;
        "application/x-extension-xhtml" = defaultBrowser;
        "application/x-extension-xht" = defaultBrowser;
      };
    };

    # Default directories
    userDirs = {
      enable = true;
      # createDirectories = true; # conflicts with impermanence

      # Make sure we're using the english ones.
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      pictures = "$HOME/Pictures";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
      videos = "$HOME/Videos";

      # I don't usually hear music from local files
      music = "$HOME/Downloads/Media/Music";
    };
  };
}
