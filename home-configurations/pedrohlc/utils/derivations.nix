utils: with utils;

rec {
  # nixpkgs-review in the right directory, in a tmux session, with a prompt before leaving, notification when it finishes successfully, and fish.
  nrpr = pkgs.callPackage ../../../packages/nixpkgs-review-in-tmux.nix { };

  # Script to open my encrypted firefox profile.
  # This is a wrapper to run firefox with a zfs-encrypted profile, requires sudo
  firefox-gate = with pkgs; callPackage ../../../packages/scripts {
    scriptName = "firefox-gate";
    substitutions = {
      "$(which firefox)" = "${firefox_nightly}/bin/firefox${firefoxSuffix}";
      "$(which zenity)" = "${pkgs.zenity}/bin/zenity";
      "$(which zfs)" = "${zfs}/bin/zfs";
    };
  };

  # swaylock with GIFs
  my-wscreensaver = pkgs.callPackage ../../../packages/my-wscreensaver.nix { };

  # PokeMMO mutable launcher
  pokemmo-launcher = with pkgs; callPackage ../../../packages/scripts {
    scriptName = "pokemmo";
    substitutions = {
      "ALSALIB:-/run/current-system/sw" = "ALSALIB:-${alsa-lib}";
      "$(which java)" = "${jdk17}/bin/java";
      "$(which gamemoderun)" = "${gamemode}/bin/gamemoderun";
    };
  };

  # a way to call FZF with GUI
  visual-fzf = pkgs.writeShellScript "visual-fzf" ''
    ${bin.terminalLauncher "/bin/sh"} -c \
      "exec ${pkgs.fzf}/bin/fzf \"\$@\" < /proc/$$/fd/0 > /proc/$$/fd/1" \
      -- "$@" 2>/dev/null
  '';

  # lock the screen
  idle-lock-script =
    pkgs.writeShellScript "idle-lock-script" ''
      exec ${pkgs.swayidle}/bin/swayidle -w \
        timeout ${toString lockTimeout} ${bin.lock} \
        before-sleep '${bin.lock}'
    '';

  # turn off the screen, turn it back on after any input
  idle-dpms-script =
    pkgs.writeShellScript "idle-dpms-script" ''
      exec ${pkgs.swayidle}/bin/swayidle -w \
        timeout ${toString dpmsTimeout} \
          'swaymsg output ${seat.displayId} power off' \
        resume 'swaymsg output ${seat.displayId} power on'
    '';

  # allows to choose the output in a GUI list
  output-chooser = pkgs.writeShellScript "output-chooser" (with bin; ''
    ${swaymsg} -t get_outputs | ${jq} '.[] | .name' | ${sed} 's/\"//g' | ${visual-fzf}
  '');

  # DLNA the KISS way
  minidlna-launcher =
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
    pkgs.writeShellScriptBin "minidlna-start" ''
      exec ${pkgs.minidlna}/sbin/minidlnad -d -f ${minidlnaConf} -v
    '';

  # I want to pick this with file managers
  mpv-hq-entry = pkgs.runCommand "mpv-hq.desktop" { } ''
    mkdir -p $out/share/applications
    cp ${config.programs.mpv.package}/share/applications/mpv.desktop $out/share/applications/mpv-hq.desktop
    substituteInPlace $out/share/applications/mpv-hq.desktop \
      --replace "Exec=mpv --" "Exec=mpv --profile=hq --" \
      --replace "Name=mpv" "Name=mpv-hq"
  '';

  # Handles picking another session when leaving sway
  alternative-session = pkgs.callPackage ../../../packages/scripts {
    scriptName = "alternative-session";
  };

  # Meme when around nvidia-proprietary because of https://github.com/GhostNaN/mpvpaper/issues/38
  nvidia-meme = pkgs.writeShellScript "nvidia-meme" ''
    exec ${pkgs.swaylock}/bin/swaylock -s fit -i ~/Pictures/nvidia-meme.jpg
  '';
}
