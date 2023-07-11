{ battery ? null
, cpuSensor ? null
, dangerousAlone ? true
, dlnaName ? null
, gitKey ? null
, gpuSensor ? null
, mainNetworkInterface ? "eno1"
, seat ? null
}:
{ config, lib, pkgs, ssot, flakes, ... }: with lib; with ssot;
let
  # Expand specs
  hasBattery = battery != null;
  hasGitKey = gitKey != null;
  hasSeat = seat != null;
  hasTouchpad = touchpad != null;
  displayBrightness = if hasSeat then seat.displayBrightness else false;
  nvidiaPrime = if hasSeat then seat.nvidiaPrime else false;
  touchpad = if hasSeat then seat.touchpad else null;

  # Preferred executables
  browser = "${pkgs.firefox-gate}/bin/firefox-gate";
  editor = "${pkgs.sublime4}/bin/subl";
  terminal = "${pkgs.alacritty}/bin/alacritty";

  # Simple executable shortcuts
  swayncClient = "${pkgs.swaynotificationcenter}/bin/swaync-client";
  grep = "${pkgs.ripgrep}/bin/rg";
  sudo = "${pkgs.sudo}/bin/sudo";
  sed = "${pkgs.gnused}/bin/sed";
  jq = "${pkgs.jq}/bin/jq";
  swaymsg = "${pkgs.sway}/bin/swaymsg";
  coreutilsBin = exe: "${pkgs.uutils-coreutils}/bin/uutils-${exe}";
  date = coreutilsBin "date";
  tr = coreutilsBin "tr";
  wc = coreutilsBin "wc";
  who = coreutilsBin "who";
  env = coreutilsBin "env";
  tty = coreutilsBin "tty";
  tmux = "${pkgs.tmux}/bin/tmux";
  fish = "${pkgs.fish}/bin/fish";

  # Complex exutables
  lock =
    # https://github.com/GhostNaN/mpvpaper/issues/38
    if nvidiaPrime then "${pkgs.swaylock}/bin/swaylock -s fit -i ~/Pictures/nvidia-meme.jpg"
    else "${pkgs.my-wscreensaver}/bin/my-wscreensaver";
  terminalLauncher = cmd: "${terminal} -t launcher -e ${cmd}";
  menu = terminalLauncher "${pkgs.sway-launcher-desktop}/bin/sway-launcher-desktop";
  menuBluetooth = terminalLauncher "${pkgs.fzf-bluetooth}/bin/fzf-bluetooth";
  menuNetwork = terminalLauncher "${pkgs.networkmanager}/bin/nmtui";

  # Repeating settings
  modifier = "Mod4";
  defaultBrowser = "firefox.desktop";
  iconTheme = "Vimix-Doder-dark";
  cursorTheme = "Breeze_Snow";
  cursorSize = 16;
  path = config.home.homeDirectory;

  # Sway modes
  modePower = "[L]ogoff | [S]hutdown | [R]eboot | [l]ock | [s]uspend";
  modeFavorites = "[f]irefox | [F]ileMgr | [v]olume | q[b]ittorrent | [T]elegram | [e]ditor | [S]potify";
  modeOtherMenus = "[b]luetooth | [n]etwork";

  # per-GPU values
  videoAcceleration = if nvidiaPrime then "nvdec-copy" else "vaapi";

  # To help with Audacious configs
  audaciousConfigGenerator = pkgs.callPackage ../shared/lib/audacious-config-generator.nix { };

  # My wallpapers
  aenami = {
    # { deviation = "A4690F4C-30E1-0484-6B27-6396E17ECF44"; sha256 = "df2cd090f45379875657a6c0a0d656c220ee832c2d36b87bde4e6f19fb0730bc"; };
    horizon = "~/Pictures/Wallpapers/Aenami-Horizon.png";
    # { deviation = "E562F7C9-7F40-C037-D10A-A26DD714B726"; sha256 = "8185dd896c22d09523bd1d9533c7bacd43b4517ba4d56f45cc9598fb7b4f2cf53"; };
    lostInBetween = "~/Pictures/Wallpapers/Aenami-Lost-in-Between.jpg";
  };

  # Different timeouts for locking screens in desktop/laptop
  lockTimeout = if dangerousAlone then "60" else "300";

  # nixpkgs-review in the right directory, in a tmux session, with a prompt before leaving, notification when it finishes successfully, and fish.
  nrpr = pkgs.callPackage ../shared/pkgs/nixpkgs-review-in-tmux.nix { };

  # a way to call FZF with GUI
  visual-fzf = pkgs.writeShellScript "visual-fzf" ''
    ${terminalLauncher "/bin/sh"} -c \
      "exec ${pkgs.fzf}/bin/fzf \"\$@\" < /proc/$$/fd/0 > /proc/$$/fd/1" \
      -- "$@" 2>/dev/null
  '';

  # turn off the screen before locking, turn it back on after any input
  ilde-script = pkgs.writeShellScript "idle-script" ''
    exec ${pkgs.swayidle}/bin/swayidle -w \
      timeout ${lockTimeout} ${idle-script-timeout}
      resume 'swaymsg output "${seat.displayId}" power on' \
      before-sleep '${lock}'
  '';

  # it's easier to debug when they're separated
  idle-script-timeout = pkgs.writeShellScript "idle-script-timeout" ''
    swaymsg output "${seat.displayId}" power off
    ${lock} &
  '';
in
{
  home.packages = with pkgs; lists.optionals hasSeat [
    swaynotificationcenter # Won't work unless here
    sway-launcher-desktop
    fzf-bluetooth
    pokemmo-launcher

    # My scripts
    nrpr
  ];

  # My beloved DE
  wayland.windowManager.sway = mkIf hasSeat {
    enable = true;
    wrapperFeatures.gtk = true;

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
        { command = "${ilde-script}"; }
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
              "Shift+s" = "exec ${pkgs.systemd}/bin/systemctl poweroff";
              "Shift+r" = "exec ${pkgs.systemd}/bin/systemctl reboot";
              "s" = "exec ${pkgs.systemd}/bin/systemctl suspend ; mode default";
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
              "shift+c" = "exec ${pkgs.google-chrome-beta}/bin/google-chrome-stable; mode default";
              "Shift+s" = "exec ((pidof ${pkgs.spotify-unwrapped}/share/spotify/.spotify-wrapped) || ${pkgs.spotify}/bin/spotify); mode default";
              "Shift+t" = "exec ${pkgs.tdesktop}/bin/telegram-desktop; mode default";
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
    '' + (strings.optionalString nvidiaPrime ''
      # Gaming
      export GAMEMODERUNEXEC="${pkgs.nvidia-offload}/bin/nvidia-offload ${env} $GAMEMODERUNEXEC"
    '');
    extraOptions = mkIf nvidiaPrime [
      "--unsupported-gpu"
    ];
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

  # GTK4 Setup
  dconf.settings."org/gnome/desktop/interface" = {
    gtk-theme = lib.mkForce "Breeze";
    color-scheme = "prefer-dark";
  };

  # Cursor setup
  home.pointerCursor = mkIf hasSeat {
    name = cursorTheme;
    package = pkgs.libsForQt5.breeze-qt5;
    gtk.enable = true;
    size = cursorSize;
  };

  # My simple and humble bar
  programs.i3status-rust = mkIf hasSeat {
    enable = true;
    bars = {
      main = {
        settings = {
          theme.theme = "solarized-dark";
          icons.icons = "awesome5";
        };
        blocks = [
          {
            block = "custom";
            command = ''echo -n ' '; ${swayncClient} -c; [ "x$(${swayncClient} -D)" = 'xtrue' ] && echo " (DND)"'';
            interval = 3;
          }
          {
            block = "custom";
            command = "echo -n ' '; ${who} | ${grep} 'pts/' | ${wc} -l | ${tr} '\\n' '/'; ${who} | ${wc} -l";
            interval = 3;
          }
          {
            block = "toggle";
            format = " $icon";
            command_state = "${pkgs.systemd}/bin/systemctl is-active -q sshd && echo a";
            command_on = "${sudo} ${pkgs.systemd}/bin/systemctl start sshd";
            command_off = "${sudo} ${pkgs.systemd}/bin/systemctl stop sshd";
            interval = 5;
          }
          {
            block = "toggle";
            format = " $icon";
            command_state = "${pkgs.bluez}/bin/bluetoothctl show | ${grep} 'Powered: yes'";
            command_on = "${sudo} ${pkgs.util-linux}/bin/rfkill unblock bluetooth && ${sudo} ${pkgs.systemd}/bin/systemctl start bluetooth && ${pkgs.bluez}/bin/bluetoothctl --timeout 4 power on";
            command_off = "${pkgs.bluez}/bin/bluetoothctl --timeout 4 power off; ${sudo} ${pkgs.systemd}/bin/systemctl stop bluetooth && ${sudo} ${pkgs.util-linux}/bin/rfkill block bluetooth";
            interval = 5;
          }
          {
            block = "toggle";
            format = " $icon";
            command_state = "${pkgs.networkmanager}/bin/nmcli r wifi | ${grep} '^d'";
            command_on = "${pkgs.networkmanager}/bin/nmcli r wifi off";
            command_off = "${pkgs.networkmanager}/bin/nmcli r wifi on";
            interval = 5;
          }
          {
            block = "net";
            device = "wlan0";
            format = "$icon $ssid ($signal_strength)";
            missing_format = "";
            interval = 5;
          }
          {
            block = "net";
            device = mainNetworkInterface;
            format = "^icon_net_down $speed_down.eng(prefix:K) ^icon_net_up $speed_up.eng(prefix:K)";
            missing_format = "";
            interval = 5;
          }
          {
            block = "disk_space";
            path = "/";
            format = "$icon $available";
            interval = 20;
            warning = 20.0;
            alert = 10.0;
          }
          {
            block = "memory";
            format = "$icon $mem_used_percents";
          }
          {
            block = "cpu";
            interval = 2;
          }
        ] ++ (lists.optional (cpuSensor != null)
          {
            block = "temperature";
            format = "$icon $average";
            chip = cpuSensor;
            interval = 5;
          }
        ) ++ (lists.optional (gpuSensor != null)
          {
            block = "temperature";
            format = "$icon $average";
            chip = gpuSensor;
            interval = 5;
          }) ++
        [
          {
            block = "sound";
          }
        ] ++ (lists.optional hasBattery
          {
            block = "battery";
            interval = 5;
            device = battery;
          }) ++
        [{
          block = "custom";
          command =
            let
              localDay = "${date} +'%d/%m'";
              braziliansTime = "TZ='America/Sao_Paulo' ${date} +'BR{%H:%M}'";
            in
            "(${localDay}; ${braziliansTime}) | ${tr} '\\n' ' '";
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
        exec ${tmux}
    '' + (strings.optionalString hasSeat ''
      elif [ "$(${tty})" = '/dev/tty1' ]; then
        # It doesn't work like this: $\{pkgs.sway}/bin/sway
        ${config.wayland.windowManager.sway.package}/bin/sway # The same one from ~/.nix-profile/bin/sway
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
  };

  xdg = {
    # Config files that I prefer to just specify
    configFile = {
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
            skin = "${path}/.local/share/audacious/Skins/135799-winamp_classic";
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
      sublimePreferences =
        let
          # This will result in a lot of errors until Colorsublime loads.
          colorSublimeThemes = "Packages/Colorsublime - Themes/cache/Colorsublime-Themes-master/themes";
        in
        mkIf hasSeat {
          target = "sublime-text/Packages/home-manager/Preferences.sublime-settings";
          text = generators.toJSON { } {
            hardware_acceleration = "opengl";
            close_windows_when_empty = false;
            rulers = [ 45 90 ];
            spell_check = false;
            lsp_format_on_save = false; # S|_|cks a lot, I prefer plugins with REAL language support

            font_face = "Borg Sans Mono";
            font_options = [ "subpixel_antialias" ];
            font_size = 8;
            fonts_list = [ "Borg Sans Mono" "DroidSansMono Nerd Font" "Fira Code" "JetBrains Mono" ]; # For FontCycler

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
      sublimeTerminus = mkIf hasSeat {
        target = "sublime-text/Packages/home-manager/Terminus.sublime-settings";
        text = generators.toJSON { } {
          default_config = {
            linux = "Fish";
          };
          shell_configs = [
            {
              name = "Fish";
              cmd = [ "${fish}" "--login" ];
              env = { };
              enable = true;
              platforms = [ "linux" "osx" ];
            }
          ];
        };
      };
      sublimeKeybindings = mkIf hasSeat {
        target = "sublime-text/Packages/home-manager/Default (Linux).sublime-keymap";
        text = generators.toJSON { } [
          { keys = [ "ctrl+k" "ctrl+z" ]; command = "zoom_pane"; args = { "fraction" = 0.9; }; }
          { keys = [ "ctrl+k" "ctrl+shift+z" ]; command = "unzoom_pane"; args = { }; }
          { keys = [ "ctrl+shift+m" ]; command = "new_window_for_project"; }
          { keys = [ "ctrl+'" ]; command = "show_panel"; args = { panel = "console"; toggle = true; }; }
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
      sublimePackages = mkIf hasSeat {
        target = "sublime-text/Packages/User/Package Control.sublime-settings";
        text = generators.toJSON { } {
          # As this list is being updated since 2014, it may contain some obsolete packages.
          installed_packages = [
            "A File Icon" # Proper icons in the sidebar
            "Babel" # React JSX syntax
            "Clang Format" # Format C/C++
            "CMake" # CMake syntax
            "Color Convert" # RGB to/from HEX
            "Colorsublime" # Many colorschemes
            "Dockerfile Syntax Highlighting" # Dockerfile syntax
            "EditorConfig" # Per-project cross-IDE preferences
            "ElixirFormatter" # Elixir format-on-save
            "ElixirSyntax" # Elixir syntax
            "Elm Format on Save" # Format Elm
            "Elm Syntax Highlighting" # Elm syntax
            "Focus File on Sidebar"
            "FontCycler" # Fast-change fonts
            "GitGutter" # Git blame and diff
            "GraphQL" # Graphql syntax
            "HexViewer" # View binary files
            "i3 wm" # i3 and sway syntax
            "INI" # Ini files syntax
            "LaTeXTools" # Texlive recommended companion
            "LDIF Syntax Highlighting" # LDAP files syntax
            "LSP" # I really hate having a socket-server that duplicates the entire editor's state, but...
            "LSP-Deno" # ...urgh, no alternative
            "LSP-elixir" # ...damm, I really need this dialyzer integration
            "MasmAssembly" # MASM syntax
            "MDX Syntax Highlighting" # MDX (JSX on Markdown) syntax
            "MIPS Syntax" # MIPS syntax 
            "MouseEventListener" # Dependency of some other plugin
            "NeoVintageous" # Vim modes for sublime
            "Nix" # Nix syntax
            "Origami" # Easy split windows into panes
            "Package Control" # Required for having all the other
            "PKGBUILD" # Arch's PKGBUILDs syntax
            "ProjectManager" # Fast-change projects
            "Prolog" # Prolog syntax
            "QML" # Qt's QML syntax
            "rainbow_csv" # See columns in CSV through coloring
            "RecentTabSort" # Re-sort tabs
            "RustFmt" # Format Rust
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
        icon = "${path}/Games/PokeMMO/data/icons/128x128.png";
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

  programs.mpv = mkIf hasSeat {
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
      "K" = "vf toggle vapoursynth=${../shared/assets/motioninterpolation.vpy}";

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
  programs.mangohud = mkIf hasSeat {
    enable = true;
    package = pkgs.mangohud_git;
    settings = {
      # functionality
      fps_limit = seat.displayRefresh;
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

  # Personal git setings
  programs.git = {
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
  programs.alacritty = mkIf hasSeat {
    enable = true;
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
  programs.helix = {
    enable = true;
    settings = {
      theme = "base16_terminal";
    };
  };

  programs.fish = {
    enable = true;
    shellAliases =
      # NOTE: Always use $PATH-relative in alias, for user hacks
      let
        jsRun = "yarn exec --offline --";
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
        src = "${../shared/assets/fish}";
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
      Install = { WantedBy = [ "default.target" ]; };
    };
}
