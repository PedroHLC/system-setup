{ config, lib, pkgs, ssot, flakes, specs, ... }@inputs:
let
  utils = import ./utils specs inputs utils;
in
with utils; {
  # I've put the bigger fishes in separate files to help readability.
  imports = [
    flakes.stylix.homeModules.stylix
    (import ./alacritty.nix utils)
    (import ./fish.nix utils)
    (import ./kvm.nix utils)
    (import ./mpv.nix utils)
    (import ./ssh.nix utils)
    (import ./theming.nix utils)
  ] ++ optionals hasLinuxSeat [
    (import ./audacious.nix utils)
    (import ./i3status-rust.nix utils)
    (import ./sunshine.nix utils)
    (import ./sway.nix utils)
    (import ./xdg.nix utils)
  ];

  home = {
    packages =
      with pseudoPkgs; with pkgs;
      (lists.optionals hasLinuxSeat [
        firefox-gate
        minidlna-launcher
        my-wscreensaver
        pokemmo-launcher
      ] ++ lists.optionals hasAppleSeat [
        apple-notify
      ] ++ lists.optionals hasSeat [
        direnv-claude
        pear-desktop
      ] ++ [
        herdr
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
            if [ -z "$TMUX" ] && [ -z "$HERDR_ENV" ] && [ "$SSH_CLIENT" != "" ]; then
              cmd=$(
                printf '%s\n' 'tmux -l' 'tmux a' 'herdr' 'fish -l' |\
                ${bin.fzf} --print-query |\
                tail -n1
              ) && exec sh -c "exec $cmd"
            ${whenTTY1}
            fi
          '';

          whenTTY1 =
            optionalString autoLogin ''
              elif [ "$(${tty})" = '/dev/tty1' ]; then
                ${deSession}
            '';

          deSession =
            ''
              # It has to be sway from home manager.
              ${config.wayland.windowManager.sway.package}/bin/sway
              # Leave the deattached tmux session we have started inside sway.
              ${tmux} send-keys -t DE 'C-c' 'C-d' || true
              # Leave to shell
              exec fish
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
        cpu_power = true;
        gpu_junction_temp = true;
        gpu_power = true;
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
        format = "openpgp";
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

    # AI (Foreign)
    claude-code = {
      enable = isMacOS;
      context = ''
        This user has Nix installed, for simple things you can `nix run nixpkgs#pkgname -- args`.

        If the user asks for an encyclopedia-like document, it means to write it in textbook prose style, with dense paragraphs and no markdown formatting.

        Some of his projects are using devenv, triggered from .envrc, but if the environment is missing, check the .envrc to find the flake reference and run commands within:

            $ nix develop <flake-ref> --impure --accept-flake-config --command bash -c '<cli commands>'

        If new ad-hoc environments are interesting, check https://devenv.sh/ad-hoc-developer-environments/

        NEVER use Python for your scripts!

        ## Notifications
        - `echo "<message>" | "apple-notify" "<title>" [sound]` — sends desktop + mobile push in one shot.
        - Sounds: `Glass` (success, default), `Basso` (failure).
      '';
      settings = {
        theme = "dark";
        effortLevel = "high";
        model = "opus";
        plansDirectory = "./tmp/plans";
        autoCompactEnabled = false;
        switchModelsOnFlag = false;
        editorMode = "vim";
        env = {
          # "CLAUDE_CODE_DISABLE_1M_CONTEXT" = "1";
          "CLAUDE_CODE_SUBAGENT_MODEL" = "opus";
        };
        permissions  = {
          defaultMode = "acceptEdits";
        };
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
