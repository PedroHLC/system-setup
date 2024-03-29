specs: { config, lib, pkgs, ssot, flakes, ... }@inputs:
let
  utils = import ./utils.nix specs inputs;
in
with utils; {
  # I've put the bigger fishes in separate files to help readability.
  imports = [
    (import ./giants/de-theming.nix utils)
    (import ./giants/i3status-rust.nix utils)
    (import ./giants/kvm.nix utils)
    (import ./giants/ssh.nix utils)
    (import ./giants/sublime-text.nix utils)
    (import ./giants/sunshine.nix utils)
    (import ./giants/sway.nix utils)
  ];

  home = {
    packages =
      with pkgs; (lists.optionals hasSeat [
        alternative-session
        firefox-gate
        minidlna-launcher
        mpv-hq-entry
        my-wscreensaver
        pokemmo-launcher
      ] ++ [
        # My scripts
        nrpr
      ]);

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
      '' + (if steamMachine then ''
        elif [ "$(${tty})" = '/dev/tty1' ]; then
          exec steam-gamescope
      '' else if autoLogin == "sway" then ''
        elif [ "$(${tty})" = '/dev/tty1' ]; then
          # It has to be sway from home manager.
          ${config.wayland.windowManager.sway.package}/bin/sway
          # Leave the deattached tmux session we have started inside sway.
          ${tmux} send-keys -t DE 'C-c' 'C-d' || true
          # Alternative sessions I might wanna run
          exec alternative-session
      '' else "") + ''
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
    };
    # Merge Audacious public config with the secrets
    activation.mergeAudacious = mkIf hasSeat (lib.hm.dag.entryAfter [ "onFilesChange" ] ''
      finalFile="$HOME/.config/audacious/config"
      if [[ ! -e "$finalFile" ]]; then
        $DRY_RUN_CMD touch "$finalFile"
        $DRY_RUN_CMD chmod 600 "$finalFile"
        $DRY_RUN_CMD cat "$HOME/.config/audacious/config.public" > "$finalFile"
        $DRY_RUN_CMD cat "$HOME/.secrets/audacious.config" >> "$finalFile"
      fi
    '');
  };

  xdg = {
    # Config files that I prefer to just specify
    configFile = {
      # Newer format for Alacritty's config
      alacritty = mkIf hasSeat {
        target = "alacritty/alacritty.toml";
        source = (pkgs.formats.toml { }).generate "alacritty.toml" config.programs.alacritty.settings;
      };
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
            chooser_cmd = output-chooser;
          };
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
      # Audacious rice
      audacious = mkIf hasSeat {
        target = "audacious/config.public";
        onChange = ''
          [[ -f "$HOME/.config/audacious/config" ]] && rm "$HOME/.config/audacious/config"
        '';
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
    dataFile = mkIf hasSeat {
      audaciousSkinWinampClassic = {
        target = "audacious/Skins/135799-winamp_classic";
        source = pkgs.audacious-skin-winamp-classic;
      };

      userChromeCss = {
        target = "userChrome.css";
        source = "${flakes.pedrochrome-css}/userChrome.css";
      };
    };
    desktopEntries = mkIf hasSeat {
      # Overwrite Firefox with my encryption-wrapper
      "firefox${firefoxSuffix}" = {
        name = "Firefox (Wayland)";
        genericName = "Web Browser";
        exec = "${firefox-gate}/bin/firefox-gate %U";
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
        genericName = "MMORPG abou leveling up and discovering new monsters";
        exec = "${pokemmo-launcher}/bin/pokemmo";
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
        gpu_junction_temp = true;
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
      userName = contact.nickname;
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
        # NOTE: Always use $PATH-relative executables in shellAliases, for user's hacks
        {
          ":q" = "exit";
          "aget" = "aria2c -s 16 -x 16 -j 16 -k 1M";
          "gpff" = "git pull --ff-only";
          "gprb" = "git pull --rebase";
          "gp@main" = "git fetch origin main && git branch -f main origin/main && git checkout main";
          "gp@master" = "git fetch origin master && git branch -f master origin/master && git checkout master";
          "gp@nixpkgs" = "git fetch upstream nixpkgs-unstable && git branch -f nixpkgs-unstable upstream/nixpkgs-unstable && git checkout nixpkgs-unstable";
          "sys" = "git --git-dir=$HOME/.system.git --work-tree=/etc/nixos";
          "@sys" = "cd /etc/nixos";
          "@nixpkgs" = "cd ~/Projects/com.pedrohlc/nixpkgs";
          "@nyx" = "cd ~/Projects/cx.chaotic/nyx";
          "@core" = "cd ~/Projects/co.timeline/core";
          "nix-roots" = "nix-store --gc --print-roots | grep -v ^/proc";
        } // attrsets.optionalAttrs hasSeat {
          "reboot-to-firmare" = "sudo bootctl set-oneshot auto-reboot-to-firmware-setup && systemctl reboot";
          "mpv-hq" = "mpv --profile=hq";
          # TODO: Move to services
          "wayvnc-main" = "wayvnc -vL trace --config ~/.secrets/wayvnc.config -o DP-2";
          "wayvnc-headless" = "wayvnc -vL trace --config ~/.secrets/wayvnc.config -o HEADLESS-1 -S /run/user/1001/wayvncctl2";
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
}
