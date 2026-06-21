utils: with utils;

{
  programs.fish = {
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
        "nix-roots" = "nix-store --gc --print-roots | grep -Pv '^\"?(/proc|{lsof})'";
        "nix-auth-gh" = "set -gx NIX_CONFIG \"access-tokens = github.com=$(gh auth token)\"";
      } // attrsets.optionalAttrs isNixOS {
        "gp@nixpkgs" = "git fetch upstream nixpkgs-unstable && git branch -f nixpkgs-unstable upstream/nixpkgs-unstable && git checkout nixpkgs-unstable";
        "@nixpkgs" = "cd ~/Projects/com.pedrohlc/nixpkgs";
        "@sys" = "cd /etc/nixos";
        "sys" = "git --git-dir=$HOME/.system.git --work-tree=/etc/nixos";
        "@nyx" = "cd ~/Projects/cx.chaotic/nyx";
      } // attrsets.optionalAttrs isMacOS (rec {
        "@core" = "cd ~/Projects/co.timeline/core";
        "@calc-rs" = "cd ~/Projects/co.timeline/calc-rs";
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
        "channel-3" = "ddcutil setvcp 60 0x06"; # Changes the display to HDMI-2
        "channel-4" = "ddcutil setvcp 60 0x0f"; # Changes the display to DP-1
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
      "tmux-a" = ''
        tmux set-option -g prefix C-a
        tmux unbind-key C-b
        tmux bind-key C-a send-prefix
        echo "tmux prefix set to Ctrl+A"
      '';
      "tmux-b" = ''
        tmux set-option -g prefix C-b
        tmux unbind-key C-a
        tmux bind-key C-b send-prefix
        echo "tmux prefix set to Ctrl+B"
      '';
    };
  };
}
