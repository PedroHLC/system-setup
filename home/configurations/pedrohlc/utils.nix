{ battery ? null
, cpuSensor ? null
, dangerousAlone ? true
, dlnaName ? null
, gitKey ? null
, gpuSensor ? null
, mainNetworkInterface ? "eno1"
, nvmeSensors ? [ ]
, seat ? null
, ups ? null
}:
{ config, lib, pkgs, ssot, flakes, nixosConfig, usingNouveau ? false, ... }:
{
  inherit battery cpuSensor dangerousAlone dlnaName gitKey gpuSensor mainNetworkInterface nvmeSensors seat ups;
  inherit config pkgs flakes nixosConfig usingNouveau;
  myLib = flakes.fp-lib;
} // (lib // ssot // rec {
  # Expand specs
  hasBattery = battery != null;
  hasUPS = ups != null;
  hasGitKey = gitKey != null;
  hasSeat = seat != null;
  hasTouchpad = touchpad != null;

  # Expand seat specs
  autoLogin = seat.autoLogin or "sway";
  displayBrightness = seat.displayBrightness or false;
  kvm = seat.kvm or null;
  nvidiaBad = nvidiaPrime && !usingNouveau;
  nvidiaPrime = seat.nvidiaPrime or false;
  steamMachine = autoLogin == "steam";
  sunshine = seat.sunshine or false;
  touchpad = if hasSeat then (seat.touchpad or false) else null;

  # Preferred executables
  browser = "${firefox-gate}/bin/firefox-gate";
  editor = "${pkgs.zed-editor_git}/bin/zeditor";
  terminal = "${config.programs.alacritty.package}/bin/alacritty";

  # Simple executable shortcuts
  swayncClient = "${pkgs.swaynotificationcenter}/bin/swaync-client";
  grep = "${pkgs.ripgrep}/bin/rg";
  sudo = "${pkgs.sudo}/bin/sudo";
  sed = "${pkgs.gnused}/bin/sed";
  jq = "${pkgs.jq}/bin/jq";
  swaymsg = "${config.wayland.windowManager.sway.package}/bin/swaymsg";
  coreutilsBin = exe: "${pkgs.uutils-coreutils}/bin/uutils-${exe}";
  date = coreutilsBin "date";
  tr = coreutilsBin "tr";
  wc = coreutilsBin "wc";
  who = coreutilsBin "who";
  env = coreutilsBin "env";
  tty = coreutilsBin "tty";
  tmux = "${pkgs.tmux}/bin/tmux";
  fish = "${config.programs.fish.package}/bin/fish";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  bluetoothctl = "${pkgs.bluez}/bin/bluetoothctl";
  nmcli = "${pkgs.networkmanager}/bin/nmcli";

  # Complex executables
  lock =
    # https://github.com/GhostNaN/mpvpaper/issues/38
    if nvidiaBad then
      pkgs.writeShellScript "nvidia-meme" ''
        exec ${pkgs.swaylock}/bin/swaylock -s fit -i ~/Pictures/nvidia-meme.jpg
      ''
    else "${my-wscreensaver}/bin/my-wscreensaver";
  terminalLauncher = cmd: "${terminal} -t launcher -e ${cmd}";
  menu = terminalLauncher "${pkgs.sway-launcher-desktop}/bin/sway-launcher-desktop";
  menuBluetooth = terminalLauncher "${pkgs.fzf-bluetooth}/bin/fzf-bluetooth";
  menuNetwork = terminalLauncher "${pkgs.networkmanager}/bin/nmtui";

  # Repeating settings
  modifier = "Mod4";
  defaultBrowser = "firefox${firefoxSuffix}.desktop";
  iconTheme = "Vimix-Doder-dark";
  homePath = config.home.homeDirectory;
  firefoxSuffix = "-nightly";

  # Sway modes
  modePower = "[L]ogoff | [S]hutdown | [R]eboot | [l]ock | [s]uspend";
  modeFavorites = "[f]irefox | [F]ileMgr | [v]olume | q[b]ittorrent | [T]elegram | [e]ditor | [t]IDAL";
  modeOtherMenus = "[b]luetooth | [n]etwork";

  # per-GPU values
  videoAcceleration = if nvidiaBad then "nvdec-copy" else "vaapi";

  # To help with Audacious configs
  audaciousConfigGenerator = pkgs.callPackage ../../../packages/audacious-config-generator.nix { };

  # Different timeouts for locking screens in desktop/laptop
  lockTimeout = if dangerousAlone then 60 else 300;
  dpmsTimeout = lockTimeout * 2;

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
      "ALSALIB:-/run/current-system/sw" = "ALSALIB:-${alsaLib}";
      "$(which java)" = "${jdk17}/bin/java";
      "$(which gamemoderun)" = "${gamemode}/bin/gamemoderun";
    };
  };

  # a way to call FZF with GUI
  visual-fzf = pkgs.writeShellScript "visual-fzf" ''
    ${terminalLauncher "/bin/sh"} -c \
      "exec ${pkgs.fzf}/bin/fzf \"\$@\" < /proc/$$/fd/0 > /proc/$$/fd/1" \
      -- "$@" 2>/dev/null
  '';

  # lock the screen
  idle-lock-script =
    pkgs.writeShellScript "idle-lock-script" ''
      exec ${pkgs.swayidle}/bin/swayidle -w \
        timeout ${toString lockTimeout} ${lock} \
        before-sleep '${lock}'
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
  output-chooser = pkgs.writeShellScript "output-chooser" ''
    ${swaymsg} -t get_outputs | ${jq} '.[] | .name' | ${sed} 's/\"//g' | ${visual-fzf}
  '';

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

  # ...
  alternative-session = pkgs.callPackage ../../../packages/scripts {
    scriptName = "alternative-session";
  };
})
