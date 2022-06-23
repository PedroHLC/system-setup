{ battery ? null
, cpuSensor
, dangerousAlone ? true
, displayBrightness ? false
, gitKey
, gpuSensor ? null
, nvidiaPrime ? false
, touchpad ? null
}:
{ pkgs, lib, ... }:
with pkgs.lib;
let
  # Some stuff that repeats across this file
  modifier = "Mod4";
  browser = "${pkgs.firefox-gate}/bin/firefox-gate";
  lock = "${pkgs.my-wscreensaver}/bin/my-wscreensaver";
  editor = "${pkgs.sublime4}/bin/subl";
  terminal = "${pkgs.alacritty}/bin/alacritty";
  menu = "${terminal} -t launcher -e ${pkgs.sway-launcher-desktop}/bin/sway-launcher-desktop";
  menuBluetooth = "${terminal} -t launcher -e ${pkgs.fzf-bluetooth}/bin/fzf-bluetooth";
  menuNetwork = "${terminal} -t launcher -e ${pkgs.networkmanager}/bin/nmtui";
  modePower = "[L]ogoff | [S]hutdown | [R]eboot | [l]ock | [s]uspend";
  modeFavorites = "[f]irefox | [F]ileMgr | [v]olume | q[b]ittorrent | [T]elegram | [e]ditor | [S]potify";
  modeOtherMenus = "[b]luetooth | [n]etwork";
  grep = "${pkgs.ripgrep}/bin/rg";
  sudo = "${pkgs.sudo}/bin/sudo";
  date = "${pkgs.uutils-coreutils}/bin/${pkgs.uutils-coreutils.prefix}date";
  defaultBrowser = "firefox.desktop";
  iconTheme = "Vimix-Doder-dark";
  cursorTheme = "Breeze_Snow";

  # per-GPU values
  videoAcceleration = if nvidiaPrime then "nvdec-copy" else "vaapi";

  # To help with Audacious configs
  audaciousConfigGenerator = pkgs.callPackage ../tools/lib/audacious-config-generator.nix { };

  # My wallpapers
  aenami = {
    # { deviation = "A4690F4C-30E1-0484-6B27-6396E17ECF44"; sha256 = "df2cd090f45379875657a6c0a0d656c220ee832c2d36b87bde4e6f19fb0730bc"; };
    horizon = "~/Pictures/Wallpapers/Aenami-Horizon.png";
    # { deviation = "E562F7C9-7F40-C037-D10A-A26DD714B726"; sha256 = "8185dd896c22d09523bd1d9533c7bacd43b4517ba4d56f45cc9598fb7b4f2cf53"; };
    lostInBetween = "~/Pictures/Wallpapers/Aenami-Lost-in-Between.jpg";
  };

  # Different timeouts for locking screens in desktop/laptop
  lockTimeout = if dangerousAlone then "60" else "300";
in
{
  home.packages = with pkgs; [
    swaynotificationcenter # Won't work unless here
    sway-launcher-desktop
    fzf-bluetooth
  ];

  # My beloved DE
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;

    config = {
      inherit modifier terminal menu;
      startup = [
        # Start locked because I use autologin
        { command = lock; }
        # Notification daemon
        { command = "${pkgs.swaynotificationcenter}/bin/swaync"; }
        # Volume and Display-brightness OSD
        { command = "${pkgs.avizo}/bin/avizo-service"; }
        # "services.swayidle" is missing "sh" in PATH -- besides I prefer having my graphics-session environ here.
        { command = "${pkgs.swayidle}/bin/swayidle -w timeout ${lockTimeout} ${lock} before-sleep ${lock}"; }
      ];
      input = {
        # Adjust to Brazilian keyboards
        "*" = { xkb_layout = "br"; };
      } // (attrsets.optionalAttrs (touchpad != null) {
        # Modern touchpad settings
        "${touchpad}" = {
          tap = "enable";
          middle_emulation = "enable";
          dwt = "enable";
        };
      });
      output = {
        "*" = { background = "${aenami.horizon} fill"; };
        "Unknown 0x0804 0x00000000" = { background = "${aenami.lostInBetween} fill"; };
      };
      focus = {
        followMouse = "yes";
        mouseWarping = true; # I want "container" -- home-manager issue #2956;
      };
      fonts = {
        names = [ "Fira Sans Mono" "monospace" ];
        size = 8.0;
      };
      window = {
        border = 1;
        titlebar = false;
        hideEdgeBorders = "both";

        commands = [
          { criteria = { app_id = "firefox"; title = "Picture-in-Picture"; }; command = "floating enable; sticky enable"; }
          { criteria = { app_id = "firefox"; title = "Firefox — Sharing Indicator"; }; command = "floating enable; sticky enable"; }
          { criteria = { app_id = ""; title = ".+\\(\\/run\\/current-system\\/sw\\/bin\\/gpg .+"; }; command = "floating enable; sticky enable"; }
          { criteria = { app_id = "telegramdesktop"; title = "TelegramDesktop"; }; command = "floating enable; stick enable"; } # Main window is called "Telegram (N)", popups are called "TelegramDesktop"
          { criteria = { title = "Slack \\| mini panel"; }; command = "floating enable; stick enable"; }
          { criteria = { title = "discord.com is sharing your screen."; }; command = "move scratchpad"; }
          { criteria = { class = "Spotify"; }; command = "opacity 0.9"; }

          # So that I have a pop-out for sway-launcher-desktop
          { criteria = { app_id = "Alacritty"; title = "^launcher$"; }; command = "floating enable; border pixel 4; sticky enable"; }

          # So that "my-wscreensaver" does what it needs on all setups
          { criteria = { title = "WScreenSaver@Global"; }; command = "fullscreen enable global; sticky enable"; }
          { criteria = { title = "WScreenSaver@eDP-1"; }; command = "move container to output eDP-1; fullscreen enable; sticky enable"; }
          { criteria = { title = "WScreenSaver@DP-1"; }; command = "move container to output DP-1; fullscreen enable; sticky enable"; }
          { criteria = { title = "WScreenSaver@DP-2"; }; command = "move container to output DP-2; fullscreen enable; sticky enable"; }
          { criteria = { title = "WScreenSaver@HDMI-A-1"; }; command = "move container to output HDMI-A-1; fullscreen enable; sticky enable"; }
        ];
      };
      keybindings = lib.mkOptionDefault ({
        # Window helpers
        "${modifier}+Shift+f" = "fullscreen toggle global";
        "${modifier}+Shift+t" = "sticky toggle";

        # Volume controls
        "XF86AudioRaiseVolume" = "exec ${pkgs.avizo}/bin/volumectl -u up";
        "XF86AudioLowerVolume" = "exec ${pkgs.avizo}/bin/volumectl -u down";
        "XF86AudioMute" = "exec ${pkgs.avizo}/bin/volumectl toggle-mute";

        # Lightweight screenshot to cliboard and temporary file
        "Print" = "exec ${pkgs.grim}/bin/grim -t png - | tee /tmp/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy -t 'image/png'";
        "${modifier}+Print" = "exec ${pkgs.grim}/bin/grim -t png -g \"$(${pkgs.slurp}/bin/slurp)\" - | tee /tmp/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy -t 'image/png'";

        # Notifications tray
        "${modifier}+Shift+n" = "exec ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";

        # Enter my extra modes
        "${modifier}+Tab" = "mode \"${modeFavorites}\"";
        "${modifier}+Shift+e" = "mode \"${modePower}\"";
        "${modifier}+Shift+d" = "mode \"${modeOtherMenus}\"";

        # My extra lot of workspaces
        "${modifier}+Ctrl+1" = "workspace C1";
        "${modifier}+Ctrl+2" = "workspace C2";
        "${modifier}+Ctrl+3" = "workspace C3";
        "${modifier}+Ctrl+4" = "workspace C4";
        "${modifier}+Ctrl+5" = "workspace C5";
        "${modifier}+Ctrl+6" = "workspace C6";
        "${modifier}+Ctrl+7" = "workspace C7";
        "${modifier}+Ctrl+8" = "workspace C8";
        "${modifier}+Ctrl+9" = "workspace C9";
        "${modifier}+Ctrl+0" = "workspace C10";
        "${modifier}+Shift+Ctrl+1" = "move container to workspace C1";
        "${modifier}+Shift+Ctrl+2" = "move container to workspace C2";
        "${modifier}+Shift+Ctrl+3" = "move container to workspace C3";
        "${modifier}+Shift+Ctrl+4" = "move container to workspace C4";
        "${modifier}+Shift+Ctrl+5" = "move container to workspace C5";
        "${modifier}+Shift+Ctrl+6" = "move container to workspace C6";
        "${modifier}+Shift+Ctrl+7" = "move container to workspace C7";
        "${modifier}+Shift+Ctrl+8" = "move container to workspace C8";
        "${modifier}+Shift+Ctrl+9" = "move container to workspace C9";
        "${modifier}+Shift+Ctrl+0" = "move container to workspace C10";
      } // (attrsets.optionalAttrs displayBrightness {
        # Display controls
        "XF86MonBrightnessUp" = "exec ${pkgs.avizo}/bin/lightctl up";
        "XF86MonBrightnessDown" = "exec ${pkgs.avizo}/bin/lightctl down";
      }) // (attrsets.optionalAttrs (touchpad != null) {
        # Allow toggling DWT (since it breaks gaming experience)
        "${modifier}+b" = "input ${touchpad} dwt enable";
        "${modifier}+Shift+b" = "input ${touchpad} dwt disable";
      }));
      bars = [{
        fonts = {
          names = [ "Font Awesome 5 Free" ];
          size = 9.0;
        };
        statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ~/.config/i3status-rust/config-main.toml";
        colors = {
          separator = "#666666";
          background = "#222222dd";
          statusline = "#dddddd";
          focusedWorkspace = { background = "#0088CC"; border = "#0088CC"; text = "#ffffff"; };
          activeWorkspace = { background = "#333333"; border = "#333333"; text = "#ffffff"; };
          inactiveWorkspace = { background = "#333333"; border = "#333333"; text = "#888888"; };
          urgentWorkspace = { background = "#2f343a"; border = "#900000"; text = "#ffffff"; };
        };
      }];

      floating.criteria = [
        { app_id = "firefox"; title = "moz-extension:.+"; }
        { app_id = "firefox"; title = "Password Required"; }
      ];

      modes = lib.mkOptionDefault {
        # Power-off menu
        "${modePower}" =
          {
            "Shift+l" = "exec ${pkgs.sway}/bin/swaymsg exit";
            "Shift+s" = "exec ${pkgs.systemd}/bin/systemctl poweroff";
            "Shift+r" = "exec ${pkgs.systemd}/bin/systemctl reboot";
            "s" = "exec ${pkgs.systemd}/bin/systemctl suspend ; mode default";
            "l" = "exec ${lock} ; mode default";
            "Return" = "mode default";
            "Escape" = "mode default";
          };

        # Common apps
        "${modeFavorites}" =
          {
            "f" = "exec ${browser}; mode default";
            "Shift+f" = "exec ${pkgs.pcmanfm-qt}/bin/pcmanfm-qt; mode default";
            "v" = "exec ${pkgs.lxqt.pavucontrol-qt}/bin/pavucontrol-qt; mode default";
            "b" = "exec ${pkgs.qbittorrent}/bin/qbittorrent; mode default";
            "e" = "exec ${editor}; mode default";
            "s" = "exec ${pkgs.slack}/bin/slack; mode default";
            "shift+o" = "exec ${pkgs.obs-studio-wrap}/bin/obs; mode default";
            "shift+c" = "exec ${pkgs.google-chrome-beta}/bin/google-chrome-stable; mode default";
            "Shift+s" = "exec ((pidof spotify) || ${pkgs.spotify}/bin/spotify); mode default";
            "Shift+t" = "exec ${pkgs.tdesktop}/bin/telegram-desktop; mode default";
            "Escape" = "mode default";
          };

        # Network + Bluetooth
        "${modeOtherMenus}" =
          {
            "b" = "exec ${menuBluetooth}; mode default";
            "n" = "exec ${menuNetwork}; mode default";
          };
      };
    };

    systemdIntegration = false;
    extraConfig = ''
      # Proper way to start portals
      exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP
    '';
    extraSessionCommands = ''
      source ${pkgs.wayland-env}
    '' + (strings.optionalString nvidiaPrime ''
      # Gaming
      export GAMEMODERUNEXEC="nvidia-offload $GAMEMODERUNEXEC"
    '');
    extraOptions = mkIf nvidiaPrime [
      "--unsupported-gpu"
    ];
  };

  # GTK Setup
  gtk = {
    enable = true;
    theme.name = "Breeze-Dark";
    iconTheme.name = iconTheme;
  };

  # Cursor setup
  home.pointerCursor = {
    name = cursorTheme;
    package = pkgs.libsForQt5.breeze-qt5;
    gtk.enable = true;
  };

  # My simple and humble bar
  programs.i3status-rust = {
    enable = true;
    bars = {
      main = {
        theme = "solarized-dark";
        icons = "awesome5";
        blocks = [
          {
            block = "custom";
            command = "echo -n ' '; who | ${grep} 'pts/' | wc -l | tr '\\n' '/'; who | wc -l";
            interval = 3;
          }
          {
            block = "toggle";
            text = " ";
            command_state = "${pkgs.systemd}/bin/systemctl is-active -q sshd && echo a";
            command_on = "${sudo} ${pkgs.systemd}/bin/systemctl start sshd";
            command_off = "${sudo} ${pkgs.systemd}/bin/systemctl stop sshd";
            interval = 5;
            #[block.theme_overrides]
            #idle_bg = "#000000";
          }
          {
            block = "toggle";
            text = "";
            command_state = "${pkgs.bluez}/bin/bluetoothctl show | ${grep} 'Powered: yes'";
            command_on = "${sudo} ${pkgs.util-linux}/bin/rfkill unblock bluetooth && ${sudo} ${pkgs.systemd}/bin/systemctl start bluetooth && ${pkgs.bluez}/bin/bluetoothctl --timeout 4 power on";
            command_off = "${pkgs.bluez}/bin/bluetoothctl --timeout 4 power off; ${sudo} ${pkgs.systemd}/bin/systemctl stop bluetooth && ${sudo} ${pkgs.util-linux}/bin/rfkill block bluetooth";
            interval = 5;
            #[block.theme_overrides]
            #idle_bg = "#000000";
          }
          {
            block = "toggle";
            text = "";
            command_state = "${pkgs.networkmanager}/bin/nmcli r wifi | ${grep} '^d'";
            command_on = "${pkgs.networkmanager}/bin/nmcli r wifi off";
            command_off = "${pkgs.networkmanager}/bin/nmcli r wifi on";
            interval = 5;
            #[block.theme_overrides]
            #idle_bg = "#000000";
          }
          {
            block = "net";
            device = "wlan0";
            format = "{ssid} ({signal_strength}) {speed_down;K*b} {speed_up;K*b}";
            hide_inactive = true;
            interval = 5;
          }
          {
            block = "disk_space";
            path = "/";
            alias = "HD";
            info_type = "available";
            unit = "GB";
            interval = 20;
            warning = 20.0;
            alert = 10.0;
            format = "{icon} {available}";
          }
          {
            block = "memory";
            display_type = "memory";
            format_mem = "{mem_used_percents}";
            clickable = false;
          }
          {
            block = "cpu";
            interval = 2;
          }
          {
            block = "temperature";
            collapsed = false;
            format = "{average}";
            chip = cpuSensor;
            interval = 5;
          }
        ] ++ (lists.optional (gpuSensor != null)
          {
            block = "temperature";
            collapsed = false;
            format = "{average}";
            chip = gpuSensor;
            interval = 5;
          }) ++
        [
          {
            block = "sound";
          }
        ] ++ (lists.optional (battery != null)
          {
            block = "battery";
            interval = 5;
            device = battery;
          }) ++
        [{
          block = "custom";
          command = "(date +'%d/%m'; TZ='America/Sao_Paulo' date +'BR{%H:%M}'; TZ='Europe/Madrid' date +'ES{%H:%M}') | tr '\\n' ' '";
          interval = 10;
        }];
      };
    };
  };

  # Files that I prefer to just specify
  home.file = {
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
        exec ${pkgs.tmux}/bin/tmux
      elif [ "$(tty)" = '/dev/tty1' ]; then
        # It doesn't work like this: \${pkgs.sway}/bin/sway
        ~/.nix-profile/bin/sway
      fi
    '';
    # `programs.tmux` looks bloatware nearby this simplist config,
    ".tmux.conf".text = ''
      set-option -g default-shell /run/current-system/sw/bin/fish
      set-option -ga terminal-overrides ",*256col*:Tc,alacritty:Tc"
    '';
  };

  xdg = {
    # Config files that I prefer to just specify
    configFile = {
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
          Mouse = {
            cursorTheme = "Breeze_Snow";
          };
        };
      };
      # Audacious rice
      audacious = {
        target = "audacious/config";
        text = audaciousConfigGenerator {
          audacious = {
            output_bit_depth = 24;
            shuffle = false;
          };
          resample = {
            default-rate = 96000;
            method = 0;
          };
          skins = {
            always_on_top = true;
            playlist_visible = false;
            skin = "${pkgs.audacious-skin-winamp-classic}";
          };
        };
      };
      # Integrate the filemanager with the rest of the system
      pcmanfm = {
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
      sublimePreferences =
        let
          # This will result in a lot of errors until Colorsublime loads.
          colorSublimeThemes = "Packages/Colorsublime - Themes/cache/Colorsublime-Themes-master/themes";
        in
        {
          target = "sublime-text-3/Packages/home-manager/Preferences.sublime-settings";
          text = generators.toJSON { } {
            hardware_acceleration = "opengl";
            close_windows_when_empty = false;
            rulers = [ 40 80 ];
            spell_check = false;
            lsp_format_on_save = true; # Requires LSP

            font_face = "Borg Sans Mono";
            font_options = [ "subpixel_antialias" ];
            font_size = 8;
            fonts_list = [ "Borg Sans Mono" "Fira Code" "JetBrains Mono" ]; # For FontCycler

            # Have both dark & light themes
            color_scheme = "auto";
            dark_color_scheme = "${colorSublimeThemes}/Rebecca-dark.tmTheme";
            light_color_scheme = "${colorSublimeThemes}/Kashmir-Light.tmTheme";
            theme = "auto";
            dark_theme = "Darkmatter.sublime-theme";
            light_theme = "Adaptive.sublime-theme";

            # Constraint NeoVintageous to a much smaller keybindings set
            vintageous_use_ctrl_keys = null;
            vintageous_use_super_keys = null;
          };
        };
      sublimeTerminus = {
        target = "sublime-text-3/Packages/home-manager/Terminus.sublime-settings";
        text = generators.toJSON { } {
          default_config = {
            linux = "Fish";
          };
          shell_configs = [
            {
              name = "Fish";
              cmd = [ "fish" "--login" ];
              env = { };
              enable = true;
              platforms = [ "linux" "osx" ];
            }
          ];
        };
      };
      sublimeKeybindings = {
        target = "sublime-text-3/Packages/home-manager/Default (Linux).sublime-keymap";
        text = generators.toJSON { } [
          { keys = [ "ctrl+k" "ctrl+z" ]; command = "zoom_pane"; args = { "fraction" = 0.9; }; }
          { keys = [ "ctrl+k" "ctrl+shift+z" ]; command = "unzoom_pane"; args = { }; }
          { keys = [ "ctrl+shift+m" ]; command = "new_window_for_project"; }
          {
            keys = [ "ctrl+alt+t" ];
            command = "terminus_open";
            args = {
              post_window_hooks = [
                [ "carry_file_to_pane" { direction = "down"; } ]
              ];
            };
          }
        ];
      };
      sublimePackages = {
        target = "sublime-text-3/Packages/User/Package Control.sublime-settings";
        text = generators.toJSON { } {
          installed_packages = [
            "A File Icon" # Proper icons in the sidebar
            "Babel" # React JSX syntax
            "Clang Format" # Format C/C++
            "CMake" # CMake syntax
            "Color Convert" # RGB to/from HEX
            "Colorsublime" # Many colorschemes
            "Dockerfile Syntax Highlighting" # Dockerfile syntax
            "EditorConfig" # Per-project cross-IDE preferences
            "Elixir" # Elixir syntax
            "Elm Format on Save" # Format Elm
            "Elm Syntax Highlighting" # Elm syntax
            "Focus File on Sidebar"
            "FontCycler" # Fast-change fonts
            "GitGutter" # Git blame and diff
            "GraphQL" # Graphql syntax
            "HexViewer" # View binary files
            "i3 wm" # i3 and sway syntax
            "INI" # Ini files syntax
            "LDIF Syntax Highlighting" # LDAP files syntax
            "MasmAssembly" # MASM syntax
            "MDX Syntax Highlighting" # MDX (JSX on Markdown) syntax
            "MIPS Syntax" # MIPS syntax 
            "MouseEventListener" # Dependency of some other plugin
            "NeoVintageous" # Vim modes for sublime
            "Nix" # Nix syntax
            "Origami" # Easy split windows into panes
            "Package Control" # Required for having all the other
            "PKGBUILD" # Arch's PKGBUILDs syntax
            "Print to HTML" # Generates colored documents from my code
            "ProjectManager" # Fast-change projects
            "Prolog" # Prolog syntax
            "QML" # Qt's QML syntax
            "rainbow_csv" # See columns in CSV through coloring
            "Reason" # Reason syntax (Requires LSP)
            "RecentTabSort" # Re-sort tabs
            "RustFmt" # FOrmat Rust
            "Sass" # Sass syntax
            "SideBarEnhancements" # Useful commands in the sidebar
            "SublimeLinter" # Generic linter
            "Tabnine" # AI-powered auto-complete
            "Terminus" # Real terminal inside sublime
            "Terraform" # Terraform syntax
            "Theme - Darkmatter" # The dark theme I use
            "Themes Menu Switcher"
            "Toggle Dark Mode" # Fast-change theme
            "TOML" # Toml syntax
            "VimModelines" # Consider "# vim set:" lines
          ];

          # Auto generated by sublime, keeping it here otherwise it will recreate the file.
          bootstrapped = true;
          in_process_packages = [ ];
        };
      };
    };
    desktopEntries = {
      # Overwrite Firefox with my encryption-wrapper
      "firefox" = {
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
    };

    # Default apps per file type
    mimeApps = {
      enable = true;
      associations = {
        added = {
          "application/octet-stream" = "sublime_text.desktop";
        };
        removed = {
          "image/png" = "google-chrome-beta.desktop";
          "image/jpeg" = "google-chrome-beta.desktop";
        };
      };
      defaultApplications = {
        "image/png" = "org.nomacs.ImageLounge.desktop";
        "image/jpeg" = "org.nomacs.ImageLounge.desktop";
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
      createDirectories = true;

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

  programs.mpv = {
    enable = true;
    # For watching animes in 60fps
    package = pkgs.wrapMpv (pkgs.mpv-unwrapped.override { vapoursynthSupport = true; }) {
      # thanks @thiagokokada
      extraMakeWrapperArgs = [
        "--prefix"
        "LD_LIBRARY_PATH"
        ":"
        "${pkgs.vapoursynth-mvtools}/lib/vapoursynth"
      ];
    };
    config = {
      # Temporary & lossless screenshots
      screenshot-format = "png";
      screenshot-directory = "/tmp";
      # for Pipewire (Let's pray for MPV native solution)
      ao = "sdl";
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
      ytdl-format = "bestvideo[height<=?1440]+bestaudio/best";
    };
    profiles = {
      # For when I plug the optical-cable
      "toslink" = {
        audio-channels = "auto";
        af = "lavcac3enc";
        audio-spdif = "ac3";
      };
    };
    bindings = {
      # Subtitle scalers
      "P" = "add sub-scale +0.1";
      "Ctrl+p" = "add sub-scale -0.1";

      # Window helpers
      "Ctrl+1" = "cycle border";
      "Alt+3" = "set window-scale 0.5";

      # For watching animes in 60fps
      "K" = "vf toggle vapoursynth=${../assets/motioninterpolation.vpy}";
    };
  };

  # Hardware/softwre OSD indicators while gaming
  programs.mangohud = {
    enable = true;
    settings = {
      arch = true;
      background_alpha = "0.05";
      battery = true;
      cpu_temp = true;
      engine_version = true;
      font_size = 17;
      fps_limit = mkIf nvidiaPrime 144;
      gl_vsync = -1;
      gpu_temp = true;
      io_read = true;
      io_write = true;
      position = "top-right";
      round_corners = 8;
      vram = true;
      vsync = 0;
      vulkan_driver = true;
      width = 260;
      wine = true;
    };
  };

  # Color filters for day/night
  services.gammastep = {
    enable = true;
    provider = "manual";
    temperature.night = 5100;
    latitude = -21.8631753;
    longitude = -47.480553;
    settings = {
      general = {
        adjustment-method = "wayland";
        brightness-night = 0.8;
        gamma-night = 0.9;
        location-provider = "manual";
      };
    };
  };

  # Personal git setings
  programs.git = {
    enable = true;
    signing = {
      key = gitKey;
      signByDefault = true;
    };
    userEmail = "root@pedrohlc.com";
    userName = "PedroHLC ☭";
    extraConfig = {
      core = {
        editor = "nvim"; # I won't specify the full path to re-use the wrapped nvim from the system setup
      };
      rerere = {
        enabled = true;
      };
      pull = {
        rebase = true;
      };
      tag = {
        gpgsign = true;
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  # My favorite and simple terminal
  programs.alacritty = {
    enable = true;
    settings = lib.mkOptionDefault {
      font = {
        normal = {
          family = "Borg Sans Mono";
        };
        size = 11.0;
      };

      window.opacity = 0.9;

      shell = {
        program = "/run/current-system/sw/bin/fish";
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

  programs.fish = {
    enable = true;
    shellAliases = {
      ":q" = "exit";
      "aget" = "aria2c -s 16 -x 16 -j 16 -k 1M";
      "elm" = "yarn exec --offline -- elm";
      "elm-app" = "yarn exec --offline -- elm-app";
      "elm-graphql" = "yarn exec --offline -- elm-graphql";
      "elm-optimize-level-2" = "yarn exec --offline -- elm-optimize-level-2";
      "elm-review" = "yarn exec --offline -- elm-review";
      "elm-test" = "yarn exec --offline -- elm-test";
      "hqmpv" = "umpv --profile=gpu-hq";
      "parcel" = "yarn exec --offline -- parcel";
      "phlc-home" = "git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME";
      "phlc-sys" = "git --git-dir=$HOME/Projects/com.pedrohlc/my-mkrootfs --work-tree=/etc/nixos";
    };
    plugins = [
      {
        name = "local-plugin";
        src = "${../assets/fish}";
      }
    ];
    shellInit = ''
      set fish_greeting '何でもは知らないわよ。知ってることだけ'
    '';
  };
}
