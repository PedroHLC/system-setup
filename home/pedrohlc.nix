{ touchpad ? null, displayBrightness ? false, cpuSensor, gpuSensor ? null, battery ? null }:
{ pkgs, lib, ... }:
let
  modifier = "Mod4";
  browser = "${pkgs.firefox-gate}/bin/firefox-gate";
  lock = "${pkgs.my-wscreensaver}/bin/my-wscreensaver";
  editor = "${pkgs.sublime4}/bin/subl";
  terminal = "${pkgs.alacritty}/bin/alacritty";
  menu = "${terminal} -t launcher -e ${pkgs.sway-launcher-desktop}/bin/sway-launcher-desktop";
  modePower = "[L]ogoff | [S]hutdown | [R]eboot | [l]ock | [s]uspend";
  modeFavorites = "[f]irefox | [F]ileMgr | [v]olume | q[b]ittorrent | [T]elegram | [e]ditor | [S]potify";
  grep = "${pkgs.ripgrep}/bin/rg";
  sudo = "${pkgs.sudo}/bin/sudo";
  date = "${pkgs.uutils-coreutils}/bin/${pkgs.uutils-coreutils.prefix}date";
in
with pkgs.lib;
{
  # My beloved DE
  wayland.windowManager.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraSessionCommands = ''
      source ${pkgs.wayland-env}
    '';
    
    config = {
      inherit modifier terminal menu;
      startup = [
        # Start locked because I use autologin
        { command = lock; }
        # Notification daemon
        { command = "${pkgs.swaynotificationcenter}/bin/swaync"; }
        # Volume and Display-brightness OSD
        { command = "${pkgs.avizo}/bin/avizo-service"; }
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
        "*" = { background = "~/.wallpaper.jpg fill"; };
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
          { criteria = { title = "Slack \| mini panel"; }; command = "floating enable; stick enable"; }
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
        "${modifier}+Print" = "exec ${pkgs.grim}/bin/grim -t png -g \"$(slurp)\" - | tee /tmp/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy -t 'image/png'";

        # Notifications tray
        "${modifier}+Shift+n" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";

        # Enter my extra modes
        "${modifier}+Tab" = "mode \"${modeFavorites}\"";
        "${modifier}+Shift+e" = "mode \"${modePower}\"";

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
      };
    };

    systemdIntegration = false;
    extraConfig = ''
      # Proper way to start portals
      include /etc/sway/config.d/*
    '';
  };

  # Lock before sleep and after a minute
  services.swayidle = {
    enable = true;
    events = [
      { event = "before-sleep"; command = lock; }
    ];
    timeouts = [
      { timeout = 60; command = lock; }
    ];
  };

  # GTK Setup
  gtk = {
    theme.name = "Breeze-Dark";
    iconTheme = "Vimix-Doder-dark";
    cursorTheme = "Breeze_Snow";
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
}
