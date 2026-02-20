{ config, lib, pkgs, ssot, flakes, specs, ... }@inputs:
let
  utils = import ./utils specs inputs utils;
in
with utils; {
  # I've put the bigger fishes in separate files to help readability.
  imports = [
    flakes.stylix.homeModules.stylix
    (import ./ssh.nix utils)
    (import ./kvm.nix utils)
    (import ./theming.nix utils)
  ] ++ optionals hasLinuxSeat [
    (import ./i3status-rust.nix utils)
    (import ./sunshine.nix utils)
    (import ./xdg.nix utils)
    (import ./audacious.nix utils)
    (import ./sway.nix utils)
  ];

  home = {
    packages =
      with pseudoPkgs; with pkgs; (lists.optionals hasLinuxSeat [
        alternative-session
        firefox-gate
        minidlna-launcher
        mpv-hq-entry
        my-wscreensaver
        pokemmo-launcher
      ] ++ lists.optionals hasSeat [
        pear-desktop
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
      ".profile".text = with bin;
        # I use autologin and forever in love with tmux sessions.
        let
          sourceHM =
            optionalString isMacOS ''
              if [ -z "$__HM_SESS_VARS_SOURCED" ]; then
                export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:$PATH"
                source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
              fi
            '';

          autoStart = ''
            if [ -z "$TMUX" ] &&  [ "$SSH_CLIENT" != "" ]; then
              exec ${tmux}
            ${whenTTY1}
            fi
          '';

          whenTTY1 =
            optionalString autoLogin ''
              elif [ "$(${tty})" = '/dev/tty1' ]; then
                ${session}
            '';

          session =
            if steamMachine != null then
              steamSession
            else
              deSession;

          deSession =
            ''
              # It has to be sway from home manager.
              ${config.wayland.windowManager.sway.package}/bin/sway
              # Leave the deattached tmux session we have started inside sway.
              ${tmux} send-keys -t DE 'C-c' 'C-d' || true
              # Alternative sessions I might wanna run
              exec alternative-session
            '';

          steamSession = with steamMachine; ''
            if ${check-sha256} '${sha256}' '/sys/class/drm/card'*'-${output}/edid' ${salt}; then
              exec env DXVK_HDR=1 steam-gamescope
            else
              ${deSession}
            fi
          '';
        in
        sourceHM + autoStart;
      # `programs.tmux` looks bloatware nearby this simplist config,
      ".tmux.conf".text = ''
        set-option -g default-shell ${bin.fish}
        # Full color range
        set-option -ga terminal-overrides ",*256col*:Tc,alacritty:Tc"
        # Expect mouse
        set -g mouse off
      '';
      # Folow child by default
      ".gdbinit".text = ''
        set follow-fork-mode child
        set detach-on-fork off
      '';
      # Boot HM on MacOS without nix-darwin
      ".zprofile" = mkIf isMacOS {
        text = ''
          source "$HOME/.profile"
        '';
      };
    };
  };

  programs = {
    atuin = {
      enable = true;
      settings = {
        auto_sync = true;
        filter_mode_shell_up_key_binding = "directory";
        inline_height = 20;
        local_timeout = 10;
        show_tabs = false;
        style = "compact";
        sync_frequency = "5m";
        sync_address = "http://${machines.lab.vpn.addr}:${toString machines.lab.vpn.atuinPort}";
      };
    };

    btop.enable = hasLinuxSeat;

    mpv =
      if hasAppleSeat then {
        enable = true;
      } else {
        enable = hasLinuxSeat;
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
          "K" = "vf toggle vapoursynth=${../../assets/motioninterpolation.vpy}";

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
    mangohud = {
      enable = hasLinuxSeat;
      package = pkgs.mangohud;
      settings = {
        # functionality
        gl_vsync = 0;
        vsync = 1;

        # appearance
        horizontal = true;
        hud_compact = true;
        hud_no_margin = true;
        table_columns = 19;
        font_size = lib.mkForce 16;
        background_alpha = lib.mkForce "0.05";

        # additional features
        battery = hasBattery;
        cpu_temp = true;
        gpu_junction_temp = true;
        io_read = true;
        io_write = true;
        vram = true;
        wine = true;
        hdr = true;

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
      settings = {
        user.email = contact.email;
        user.name = contact.nickname;
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
          autoStash = true;
        };
        alias = {
          "cehckout" = "checkout";
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
    alacritty = {
      enable = hasSeat;
      package = pkgs.alacritty;
      settings = {
        window.opacity = lib.mkForce 0.9;

        terminal.shell = {
          program = "${bin.tmux}";
          args = [ "-l" ];
        };

        keyboard.bindings =
          if ctrlNearSpaceKeyMap
          then importJSON ../../assets/alacritty-apple-like-mods.json
          else [ ];
      };
    };

    # Text editor
    helix = {
      enable = true;
      package = pkgs.evil-helix;
      settings = {
        keys.normal = {
          V = [ "select_mode" "extend_to_line_bounds" ];
        };
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
          "@nixpkgs" = "cd ~/Projects/com.pedrohlc/nixpkgs";
          "@core" = "cd ~/Projects/co.timeline/core";
          "@calc-rs" = "cd ~/Projects/co.timeline/calc-rs";
          "nix-roots" = "nix-store --gc --print-roots | grep -Pv '^(/proc|{lsof})'";
        } // attrsets.optionalAttrs isNixOS {
          "@sys" = "cd /etc/nixos";
          "sys" = "git --git-dir=$HOME/.system.git --work-tree=/etc/nixos";
        } // attrsets.optionalAttrs isMacOS (rec {
          "@sys" = "cd ~/Projects/com.pedrohlc/system-setup";
          "poweroff" = "exec osascript -e 'tell application \"Finder\" to shut down'";
          "firewall" = "/usr/libexec/ApplicationFirewall/socketfilterfw";
          "firewall-status" = "${firewall} --getglobalstate --getblockall --getallowsigned --getstealthmode --listapps";
          "zeditor" = "/Applications/Zed.app/Contents/MacOS/cli";
        }) // attrsets.optionalAttrs (hasLinuxSeat) {
          "reboot-to-firmare" = "sudo bootctl set-oneshot auto-reboot-to-firmware-setup && systemctl reboot";
          "mpv-hq" = "mpv --profile=hq";
          "uxplay-ready" = "uxplay -h265 -as 0 -fps 60 -srgb -vs waylandsink -vd vah265dec";
          # TODO: Move to services
          "wayvnc-main" = "wayvnc -vL trace --config ~/.secrets/wayvnc.config -o ${seat.displayId}";
          "wayvnc-headless" = "wayvnc -vL trace --config ~/.secrets/wayvnc.config -o HEADLESS-1 -S /run/user/1001/wayvncctl2";
        } // attrsets.optionalAttrs (hasLinuxSeat && seat.displayId == "DP-1") {
          # Yes, this is a pun with VHF TV
          "channel-3" = "ddcutils setvcp 60 0x06"; # Changes the display to HDMI-2
          "channel-4" = "ddcutils setvcp 60 0x0f"; # Changes the display to DP-1
        };
      plugins = [
        {
          name = "local-plugin";
          src = "${../../assets/fish}";
        }
      ] ++ optionals isMacOS [
        {
          name = "foreign-env";
          src = toString (with pkgs; runCommand "foreign-env" { } ''
            mkdir $out
            ln -s ${fishPlugins.foreign-env}/share/fish/vendor_functions.d $out/functions
          '');
        }
      ];
      shellInit = ''
        set -g SHELL "${config.programs.fish.package}/bin/fish"
      '' + optionalString isMacOS ''
        fish_add_path -p /nix/var/nix/profiles/default/bin
        fish_add_path -p "$HOME/.nix-profile/bin"
        fenv source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
      '';
      interactiveShellInit = ''
        set fish_greeting '何でもは知らないわよ。知ってることだけ'
      '';
      functions = {
        "ghpr-as" = "git fetch origin pull/$argv[1]/head:$argv[2]";
        "ghupr-as" = "git fetch upstream pull/$argv[1]/head:$argv[2]";
      };
    };

    yt-dlp = {
      enable = hasLinuxSeat;
      package = pkgs.yt-dlp;
      settings = {
        netrc = true;
        extractor-args = "crunchyrollbeta:hardsub=en-US";
      };
    };

    # dev env for my projects
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        whitelist.prefix = [ "~/Projects" ];
      };
      # Fish-only
      enableBashIntegration = false;
      enableNushellIntegration = false;
      enableZshIntegration = isMacOS;
    };

    # AI
    claude-code = {
      enable = true;
      memory.text = ''
        This user has Nix installed, for simple things you can `nix run nixpkgs#pkgname -- args`.

        If the user asks for an encyclopedia-like document, it means to write it in textbook prose style, with dense paragraphs and no markdown formatting.

        Some of his projects are using devenv, triggered from .envrc, but if the environment is missing, run commands within:

            $ devenv shell -- cli args

        If new ad-hoc environments are interesting, check https://devenv.sh/ad-hoc-developer-environments/
      '';
      settings = {
        theme = "dark";
        includeCoAuthoredBy = true;
      };
    };
  };

  # Volume and Display-brightness OSD
  services.avizo.enable = hasLinuxSeat;

  # Color filters for day/night
  services.gammastep = {
    enable = hasLinuxSeat;
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
