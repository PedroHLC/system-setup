utils: with utils;

# My beloved DE
mkIf hasSeat {
  home.packages = with pkgs; lists.optionals hasSeat [
    swaynotificationcenter # Won't work unless here
    sway-launcher-desktop
    fzf-bluetooth
  ];
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    package =
      let
        cfg = config.wayland.windowManager.sway;
      in
      pkgs.sway_git.override {
        inherit (cfg) extraSessionCommands extraOptions;
        withBaseWrapper = cfg.wrapperFeatures.base;
        withGtkWrapper = cfg.wrapperFeatures.gtk;
      };

    config = {
      inherit modifier terminal menu;
      defaultWorkspace = "workspace number 1";
      startup = [
        # Start locked because I use autologin
        { command = "${lock}"; }
        # Notification daemon
        { command = "${pkgs.swaynotificationcenter}/bin/swaync"; }
        # Volume and Display-brightness OSD
        { command = "${pkgs.avizo}/bin/avizo-service"; }
        # "services.swayidle" is missing "sh" in PATH -- besides I prefer having my graphics-session environ here.
        { command = "${idle-lock-script}"; }
        { command = "${idle-dpms-script}"; }
        # A tmux session that knows about DE environment
        { command = "${tmux} new-session -ds DE"; }
      ];
      input = {
        # Adjust to Brazilian keyboards
        "*" = { xkb_layout = "br"; };
      } // (attrsets.optionalAttrs hasTouchpad {
        # Modern touchpad settings
        "${touchpad}" = {
          tap = "enable";
          middle_emulation = "enable";
          dwt = "enable";
        };
      });
      output = {
        "*" = {
          background = "${aenami.horizon} fill";
          max_render_time = "1";
          # In 60Hz display, "adaptive_sync" makes electron apps laggy
          adaptive_sync = "off";
        };
        "Unknown 0x0804 0x00000000" = {
          # Laptop's display
          background = "${aenami.lostInBetween} fill";
        };
        "Goldstar Company Ltd LG ULTRAWIDE 0x00000101" = {
          # FreeSync looks good with 75Hz
          adaptive_sync = "on";
          mode = "2560x1080@75Hz";
        };
        "Samsung Electric Company LU28R55 HX5R701479" = {
          render_bit_depth = "10";
        };
        "HEADLESS-1" = {
          resolution = "1600x900";
          position = "${toString seat.displayWidth},${toString (seat.displayHeight - 10)}";
          bg = "#008080 solid_color";
        };
        "${seat.displayId}" = with seat; {
          position = "0,0";
          mode = "${toString displayWidth}x${toString displayHeight}@${toString displayRefresh}Hz";
        };
      };
      workspaceOutputAssign = [
        { output = "HEADLESS-1"; workspace = "0"; }
        { output = "HEADLESS-1"; workspace = "C0"; }
      ];
      focus = {
        followMouse = "yes";
        mouseWarping = "container";
      };
      fonts = {
        names = [ "Fira Sans Mono" "monospace" ];
        size = 8.0;
      };
      floating.border = 1;
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
          { criteria = { app_id = "zenity"; title = "firefox-gate"; }; command = "floating enable; stick enable"; }

          # Don't lock my screen if there is anything fullscreen, I may be gaiming
          { criteria = { shell = ".*"; }; command = "inhibit_idle fullscreen"; }

          # So that I have a pop-out for sway-launcher-desktop
          { criteria = { app_id = "Alacritty"; title = "^launcher$"; }; command = "floating enable; border pixel 4; sticky enable"; }
        ];
      };
      keybindings = mkOptionDefault ({
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
        "${modifier}+Shift+n" = "exec ${swayncClient} -t -sw";

        # Enter my extra modes
        "${modifier}+Tab" = "mode \"${modeFavorites}\"";
        "${modifier}+Shift+e" = "mode \"${modePower}\"";
        "${modifier}+Shift+d" = "mode \"${modeOtherMenus}\"";

        # The missing workspace
        "${modifier}+0" = "workspace 0";
        "${modifier}+Shift+0" = "move container to workspace 0";

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
        "${modifier}+Ctrl+0" = "workspace C0";
        "${modifier}+Shift+Ctrl+1" = "move container to workspace C1";
        "${modifier}+Shift+Ctrl+2" = "move container to workspace C2";
        "${modifier}+Shift+Ctrl+3" = "move container to workspace C3";
        "${modifier}+Shift+Ctrl+4" = "move container to workspace C4";
        "${modifier}+Shift+Ctrl+5" = "move container to workspace C5";
        "${modifier}+Shift+Ctrl+6" = "move container to workspace C6";
        "${modifier}+Shift+Ctrl+7" = "move container to workspace C7";
        "${modifier}+Shift+Ctrl+8" = "move container to workspace C8";
        "${modifier}+Shift+Ctrl+9" = "move container to workspace C9";
        "${modifier}+Shift+Ctrl+0" = "move container to workspace C0";
      } // (attrsets.optionalAttrs displayBrightness {
        # Display controls
        "XF86MonBrightnessUp" = "exec ${pkgs.avizo}/bin/lightctl up";
        "XF86MonBrightnessDown" = "exec ${pkgs.avizo}/bin/lightctl down";
      }) // (attrsets.optionalAttrs hasTouchpad {
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
        extraConfig = ''
          output "${seat.displayId}"
        '';
      }];

      floating.criteria = [
        { app_id = "firefox"; title = "^moz-extension:"; }
        { app_id = "firefox"; title = "^Password Required"; }
        # Zoom is messy
        { app_id = ""; title = "^Settings$"; }
        { app_id = ""; title = "^[zZ]oom$"; }
        { app_id = ""; title = "^Zoom "; }
        { app_id = ""; title = "^Advanced .*Options…$"; }
        { app_id = ""; title = "^Participants \\(.+\\)$"; }
        { app_id = ""; title = "^Create Breakout Rooms$"; }
      ];

      modes =
        let
          withLeaveOptions = attrs: attrs // {
            "Return" = "mode default";
            "Escape" = "mode default";
          };
        in
        mkOptionDefault {
          # Power-off menu
          "${modePower}" =
            withLeaveOptions {
              "Shift+l" = "exec ${swaymsg} exit";
              "Shift+s" = "exec ${systemctl} poweroff";
              "Shift+r" = "exec ${systemctl} reboot";
              "s" = "exec ${systemctl} suspend ; mode default";
              "l" = "exec ${lock} ; mode default";
            };

          # Common apps
          "${modeFavorites}" =
            withLeaveOptions {
              "f" = "exec ${browser}; mode default";
              "Shift+f" = "exec ${pkgs.pcmanfm-qt}/bin/pcmanfm-qt; mode default";
              "v" = "exec ${pkgs.lxqt.pavucontrol-qt}/bin/pavucontrol-qt; mode default";
              "b" = "exec ${pkgs.qbittorrent}/bin/qbittorrent; mode default";
              "e" = "exec ${editor}; mode default";
              "s" = "exec ${pkgs.slack}/bin/slack; mode default";
              "shift+o" = "exec ${pkgs.obs-studio-wrapped}/bin/obs; mode default";
              "shift+c" = "exec ${pkgs.google-chrome}/bin/google-chrome-stable; mode default";
              "Shift+s" = "exec ((pidof ${pkgs.spotify-unwrapped}/share/spotify/.spotify-wrapped) || ${pkgs.spotify}/bin/spotify); mode default";
              "Shift+t" = "exec ${pkgs.telegram-desktop_git}/bin/telegram-desktop; mode default";
            };

          # Network + Bluetooth
          "${modeOtherMenus}" =
            withLeaveOptions {
              "b" = "exec ${menuBluetooth}; mode default";
              "n" = "exec ${menuNetwork}; mode default";
            };
        };
    };

    systemd.enable = true;
    extraSessionCommands = ''
      source ${pkgs.wayland-env}/bin/wayland-env
      export STEAM_FORCE_DESKTOPUI_SCALING=1
    '' + (strings.optionalString nvidiaPrime (if usingNouveau then ''
      # Gaming
      export GAMEMODERUNEXEC="DRI_PRIME=1 ${env} $GAMEMODERUNEXEC"
    '' else ''
      # Gaming
      export GAMEMODERUNEXEC="${pkgs.nvidia-offload}/bin/nvidia-offload ${env} $GAMEMODERUNEXEC"
    ''));
    extraOptions = mkIf (nvidiaPrime && !usingNouveau) [
      "--unsupported-gpu"
    ];
  };
}
