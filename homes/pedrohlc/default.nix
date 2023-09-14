specs: { config, lib, pkgs, ssot, flakes, ... }@inputs:
let
  utils = import ./utils.nix specs inputs;
in
with utils; {
  # I've put the bigger fishes in separate files to help readability.
  imports = [
    (import ./giants/sway.nix utils)
    (import ./giants/i3status-rust.nix utils)
    (import ./giants/sublime-text.nix utils)
  ];

  home = {
    packages = with pkgs; (lists.optionals hasSeat [
      pokemmo-launcher
    ] ++ [
      # My scripts
      nrpr
    ]);

    # Cursor setup
    pointerCursor = mkIf hasSeat {
      name = cursorTheme;
      package = pkgs.libsForQt5.breeze-qt5;
      gtk.enable = true;
      size = cursorSize;
    };

    # Files that I prefer to just specify
    file = {
      # I Don't really use bash, so I don't want its history...
      ".bashrc".text = ''
        unset HISTFILE
      '';
      # Don't forget to always load my .profile
      ".bash_profile".text = ''
        [[ -f ~/.bashrc ]] && . ~/.bashrc
        [[ -f ~/.profile ]] && . ~/.profile
      '';
      # I use autologin and forever in love with tmux sessions.
      ".profile".text = ''
        if [ -z "$TMUX" ] &&  [ "$SSH_CLIENT" != "" ]; then
          exec ${tmux}
      '' + (strings.optionalString hasSeat ''
        elif [ "$(${tty})" = '/dev/tty1' ]; then
          # It has to be the one from home manager.
          ${config.wayland.windowManager.sway.package}/bin/sway
          ${tmux} send-keys -t DE 'C-c' 'C-d' || true
      '') + ''
        fi
      '';
      # `programs.tmux` looks bloatware nearby this simplist config,
      ".tmux.conf".text = ''
        set-option -g default-shell ${fish}
        # Full color range
        set-option -ga terminal-overrides ",*256col*:Tc,alacritty:Tc"
        # Expect mouse
        set -g mouse off
      '';
      # OpenMoHAA
      ".moh/OpenMoHAA" = mkIf hasSeat {
        recursive = true;
        source = pkgs.openmohaa;
      };
    };
  };

  # GTK Setup
  gtk = mkIf hasSeat {
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
    gtk-theme = lib.mkForce "Breeze";
    color-scheme = "prefer-dark";
  };

  xdg = {
    # Config files that I prefer to just specify
    configFile = {
      # Newer format for Alacritty's config
      alacritty = mkIf hasSeat {
        target = "alacritty/alacritty.toml";
        source = (pkgs.formats.toml { }).generate "alacritty.toml" config.programs.alacritty.settings;
      };
      # Allow me to choose which display to share in a list.
      wlrPortal = mkIf hasSeat {
        target = "xdg-desktop-portal-wlr/config";
        text = generators.toINI { } {
          screencast = {
            chooser_type = "dmenu";
            chooser_cmd =
              pkgs.writeShellScript "output-chooser" ''
                ${swaymsg} -t get_outputs | ${jq} '.[] | .name' | ${sed} 's/\"//g' | ${visual-fzf}
              '';
          };
        };
      };
      # The entire qt module is useless for me as I use Breeze with Plasma's platform-theme.
      kdeglobals = mkIf hasSeat {
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
      kcminputrc = mkIf hasSeat {
        text = generators.toINI { } {
          Mouse = { inherit cursorTheme cursorSize; };
        };
      };
      # Notifications
      swaync = mkIf hasSeat {
        target = "swaync/config.json";
        text = generators.toJSON { } {
          "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/configSchema.json";
          positionX = seat.notificationX;
          positionY = seat.notificationY;
        };
      };
      # Audacious rice (TODO: NEEDS REWORK)
      audacious = mkIf hasSeat {
        # Right now I need to find a way to insert scrobler token here, so I'll keep it as a "template".
        target = "audacious/config.template";
        text = audaciousConfigGenerator {
          audacious = {
            shuffle = false;
          };
          pipewire = {
            volume_left = 100;
            volume_right = 100;
          };
          resample = {
            default-rate = 96000;
            method = 0;
          };
          skins = {
            always_on_top = true;
            playlist_visible = false;
            skin = "${homePath}/.local/share/audacious/Skins/135799-winamp_classic";
          };
        };
      };
      # Integrate the filemanager with the rest of the system
      pcmanfm = mkIf hasSeat {
        target = "pcmanfm-qt/default/settings.conf";
        text = generators.toINI { } {
          Behavior = {
            NoUsbTrash = true;
            SingleWindowMode = true;
          };
          System = {
            Archiver = "xarchiver";
            FallbackIconThemeName = iconTheme;
            Terminal = "${terminal}";
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
    };
    # Other data files
    dataFile = {
      audaciousSkinWinampClassic = mkIf hasSeat {
        source = pkgs.audacious-skin-winamp-classic;
        target = "audacious/Skins/135799-winamp_classic";
      };

      userChromeCss = mkIf hasSeat {
        source = "${flakes.pedrochrome-css}/userChrome.css";
        target = "userChrome.css";
      };
    };
    desktopEntries = {
      # Overwrite Firefox with my encryption-wrapper
      "firefox" = mkIf hasSeat {
        name = "Firefox (Wayland)";
        genericName = "Web Browser";
        exec = "${pkgs.firefox-gate}/bin/firefox-gate %U";
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
      "pokemmo" = mkIf hasSeat {
        name = "PokeMMO";
        genericName = "MMORPG abou leveling up and discovering new monsters";
        exec = "${pkgs.pokemmo-launcher}/bin/pokemmo";
        terminal = false;
        categories = [ "Game" ];
        type = "Application";
        icon = "${homePath}/Games/PokeMMO/data/icons/128x128.png";
      };
    };

    # Default apps per file type
    mimeApps = mkIf hasSeat {
      enable = true;
      associations = {
        added = {
          "application/octet-stream" = "sublime_text.desktop";
        };
        removed = {
          "image/gif" = "google-chrome-beta.desktop";
          "image/jpeg" = "google-chrome-beta.desktop";
          "image/png" = "google-chrome-beta.desktop";
          "image/webp" = "google-chrome-beta.desktop";
        };
      };
      defaultApplications = {
        "image/gif" = "org.nomacs.ImageLounge.desktop";
        "image/jpeg" = "org.nomacs.ImageLounge.desktop";
        "image/png" = "org.nomacs.ImageLounge.desktop";
        "image/webp" = "org.nomacs.ImageLounge.desktop";
        "application/pdf" = "firefox.desktop";

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

  programs = {
    mpv = mkIf hasSeat {
      enable = true;
      # For watching animes in 60fps
      package = pkgs.mpv-vapoursynth;
      config = {
        # Temporary & lossless screenshots
        screenshot-format = "png";
        screenshot-directory = "/tmp";
        # for Pipewire (Let's pray for MPV native solution)
        ao = "openal";
        # I don't usually plug my PC in a home-theater
        audio-channels = "stereo";

        # So dual-audio anime don't go crazy;
        alang = "jpn,eng";
        slang = "eng";

        # GPU & Wayland
        hwdec = "${videoAcceleration}";
        vo = "gpu";
        gpu-context = "waylandvk";
        gpu-api = "vulkan";

        # YouTube quality
        ytdl-format =
          if seat.displayHeight <= 1080 then
            "bestvideo[height<=?1440]+bestaudio/best"
          else
            "bestvideo[height<=?2160]+bestaudio/best";

      };
      profiles = {
        # For when I plug the optical-cable
        "toslink" = {
          audio-channels = "auto";
          af = "lavcac3enc";
          audio-spdif = "ac3";
        };
        "hq" = {
          profile = "gpu-hq";
          scale = "ewa_lanczossharp";
          cscale = "ewa_lanczossharp";
          tscale = "oversample";
        };
      };
      bindings = {
        # Subtitle scalers
        "P" = "add sub-scale +0.1";
        "Ctrl+p" = "add sub-scale -0.1";

        # Window helpers
        "Alt+3" = "set window-scale 0.5";
        "Alt+4" = "cycle border";

        # For watching animes in 60fps
        "K" = "vf toggle vapoursynth=${../../shared/assets/motioninterpolation.vpy}";

        # For anime 4k
        "CTRL+1" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode A (HQ)"'';
        "CTRL+2" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_Soft_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode B (HQ)"'';
        "CTRL+3" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode C (HQ)"'';
        "CTRL+4" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_M.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode A+A (HQ)"'';
        "CTRL+5" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_Soft_VL.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_Soft_M.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode B+B (HQ)"'';
        "CTRL+6" = ''no-osd change-list glsl-shaders set "${pkgs.anime4k}/Anime4K_Clamp_Highlights.glsl:${pkgs.anime4k}/Anime4K_Upscale_Denoise_CNN_x2_VL.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x2.glsl:${pkgs.anime4k}/Anime4K_AutoDownscalePre_x4.glsl:${pkgs.anime4k}/Anime4K_Restore_CNN_M.glsl:${pkgs.anime4k}/Anime4K_Upscale_CNN_x2_M.glsl"; show-text "Anime4K: Mode C+A (HQ)"'';
        "CTRL+0" = ''no-osd change-list glsl-shaders clr ""; show-text "GLSL shaders cleared"'';
      };
    };

    # Hardware/softwre OSD indicators while gaming
    mangohud = mkIf hasSeat {
      enable = true;
      package = pkgs.mangohud_git;
      settings = {
        # functionality
        gl_vsync = 0;
        vsync = 1;

        # appearance
        horizontal = true;
        hud_compact = true;
        hud_no_margin = true;
        table_columns = 19;
        font_size = 16;
        background_alpha = "0.05";

        # additional features
        battery = hasBattery;
        cpu_temp = true;
        gpu_temp = true;
        io_read = true;
        io_write = true;
        vram = true;
        wine = true;

        # cool, but not always necessary
        # keeping here for remembering
        # arch = true;
        # vulkan_driver = true;
        # gpu_name = true;
        # engine_version = true;
      };
    };

    # Personal git setings
    git = {
      enable = true;
      lfs.enable = true;
      signing = mkIf hasGitKey {
        key = gitKey;
        signByDefault = true;
      };
      userEmail = contact.email;
      userName = "${contact.nickname} ☭";
      extraConfig = {
        core = {
          editor = "hx"; # I won't specify the full path to re-use the package from system setup
        };
        rerere = {
          enabled = true;
        };
        pull = {
          rebase = true;
        };
        tag = {
          gpgsign = hasGitKey;
        };
        init = {
          defaultBranch = "main";
        };
        rebase = {
          # When interactive-rebasing, keep original commiter.
          instructionFormat = "%s%nexec GIT_COMMITTER_DATE=\"%cI\" GIT_COMMITTER_NAME=\"%cN\" GIT_COMMITTER_EMAIL=\"%cE\" git commit --amend --no-edit%n";
        };
        # pull with rebase on everything except main/master
        "branch \"main\"" = {
          rebase = false;
          ff-only = true;
        };
        "branch \"master\"" = {
          rebase = false;
          ff-only = true;
        };
      };
    };

    # My favorite and simple terminal
    alacritty = mkIf hasSeat {
      enable = false; # Module is using "yml" which isn't compatible with newer version.
      settings = mkOptionDefault {
        font = {
          normal = {
            family = "Borg Sans Mono";
          };
          size = 11.0;
        };

        window.opacity = 0.9;

        shell = {
          program = "${fish}";
          args = [ "--login" ];
        };

        colors = {
          primary = {
            background = "#161821";
            foreground = "#d2d4de";
          };
          normal = {
            black = "#161821";
            red = "#e27878";
            green = "#b4be82";
            yellow = "#e2a478";
            blue = "#84a0c6";
            magenta = "#a093c7";
            cyan = "#89b8c2";
            white = "#c6c8d1";
          };
          bright = {
            black = "#6b7089";
            red = "#e98989";
            green = "#c0ca8e";
            yellow = "#e9b189";
            blue = "#91acd1";
            magenta = "#ada0d3";
            cyan = "#95c4ce";
            white = "#d2d4de";
          };
        };
      };
    };

    # Text editor
    helix = {
      enable = true;
      settings = {
        theme = "base16_terminal";
      };
    };

    fish = {
      enable = true;
      shellAliases =
        # NOTE: Always use $PATH-relative in alias, for user hacks
        let
          jsRun = "yarn exec --prefer-offline --";
        in
        {
          ":q" = "exit";
          "aget" = "aria2c -s 16 -x 16 -j 16 -k 1M";
          "gpff" = "git pull --ff-only";
          "gprb" = "git pull --rebase";
          "gp@main" = "git fetch origin && git branch -f main origin/main && git checkout main";
          "gp@master" = "git fetch origin && git branch -f master origin/master && git checkout master";
          "gp@nixpkgs" = "git fetch upstream && git branch -f nixpkgs-unstable upstream/nixpkgs-unstable && git checkout nixpkgs-unstable";
          "phlc-sys" = "git --git-dir=$HOME/.system.git --work-tree=/etc/nixos";
          "@system" = "cd /etc/nixos";
          "@nixpkgs" = "cd ~/Projects/com.pedrohlc/nixpkgs";
          "@nyx" = "cd ~/Projects/cx.chaotic/nyx";
          "nix-roots" = "nix-store --gc --print-roots | grep -v ^/proc";
        } // attrsets.optionalAttrs hasSeat {
          "reboot-to-firmare" = "sudo bootctl set-oneshot auto-reboot-to-firmware-setup && systemctl reboot";
          "elm" = "${jsRun} elm";
          "elm-app" = "${jsRun} elm-app";
          "elm-graphql" = "${jsRun} elm-graphql";
          "elm-optimize-level-2" = "${jsRun} elm-optimize-level-2";
          "elm-review" = "${jsRun} elm-review";
          "elm-test" = "${jsRun} elm-test";
          "mpv-hq" = "mpv --profile=hq";
          "parcel" = "${jsRun} parcel";
          "@apollo" = "cd ~/Projects/br.com.mindlab/apollo";
        };
      plugins = [
        {
          name = "local-plugin";
          src = "${../../shared/assets/fish}";
        }
      ];
      shellInit = ''
        set fish_greeting '何でもは知らないわよ。知ってることだけ'
        set -g SHELL "${config.programs.fish.package}/bin/fish"
      '';
      functions = {
        "ghpr-as" = "git fetch origin pull/$argv[1]/head:$argv[2]";
        "ghupr-as" = "git fetch upstream pull/$argv[1]/head:$argv[2]";
      };
    };
    # Crunchyroll and SAMSUNG Tizen don't mix, so I have to DLNA-it.
    yt-dlp = mkIf hasSeat {
      enable = true;
      package = pkgs.yt-dlp_git;
      settings = {
        netrc = true;
        extractor-args = "crunchyrollbeta:hardsub=en-US";
      };
    };

    # dev env for my projects
    direnv = {
      enable = true;
      # Fish-only
      enableBashIntegration = false;
      enableNushellIntegration = false;
      enableZshIntegration = false;
    };
  };

  # Color filters for day/night
  services.gammastep = mkIf hasSeat {
    enable = true;
    provider = "manual";
    temperature.night = 5100;
    latitude = -23.438343565214307;
    longitude = -47.06493998075002;
    settings = {
      general = {
        adjustment-method = "wayland";
        brightness-night = 0.8;
        gamma-night = 0.9;
        location-provider = "manual";
      };
    };
  };

  # DLNA
  systemd.user.services.minidlna =
    let
      minidlnaConf = pkgs.writeTextFile {
        name = "minidlna.conf";
        text = ''
          media_dir=V,/home/pedrohlc/Torrents
          friendly_name=${dlnaName}
          inotify=yes
          db_dir=/tmp
        '';
      };
    in
    mkIf (dlnaName != null) {
      Unit = {
        Description = "MiniDLNA service";
        After = [ "network.target" ];
      };
      Service = {
        ExecStart = "${pkgs.minidlna}/sbin/minidlnad -d -f ${minidlnaConf} -v";
      };
      Install.WantedBy = [ ];
    };
}
