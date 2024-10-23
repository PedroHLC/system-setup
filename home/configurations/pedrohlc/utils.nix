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
, isLinux ? true
, isDarwin ? false
}:
{ config, lib, pkgs, ssot, flakes, nixosConfig ? null, usingNouveau ? false, ... }@scope:
self:
{
  inherit battery cpuSensor dangerousAlone dlnaName gitKey gpuSensor mainNetworkInterface nvmeSensors seat ups isLinux isDarwin;
  inherit config pkgs flakes nixosConfig usingNouveau;
  myLib = flakes.fp-lib;
} // (lib // ssot // rec {
  pseudoPkgs = import ./pseudo-packages.nix self;

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

  bin = rec {
    # Preferred executables
    browser = "${pseudoPkgs.firefox-gate}/bin/firefox-gate";
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
      if nvidiaBad then pseudoPkgs.nvidia-meme
      else "${pseudoPkgs.my-wscreensaver}/bin/my-wscreensaver";
    terminalLauncher = cmd: "${terminal} -t launcher -e ${cmd}";
    menu = terminalLauncher "${pkgs.sway-launcher-desktop}/bin/sway-launcher-desktop";
    menuBluetooth = terminalLauncher "${pkgs.fzf-bluetooth}/bin/fzf-bluetooth";
    menuNetwork = terminalLauncher "${pkgs.networkmanager}/bin/nmtui";
  };

  # Repeating settings
  modifier = "Mod4";
  defaultBrowser = "firefox${firefoxSuffix}.desktop";
  iconTheme = "Vimix-Doder-dark";
  homePath = config.home.homeDirectory;
  firefoxSuffix = "-nightly";

  # per-GPU values
  videoAcceleration = if nvidiaBad then "nvdec-copy" else "vaapi";

  # To help with Audacious configs
  audaciousConfigGenerator = pkgs.callPackage ../../../packages/audacious-config-generator.nix { };

  # Different timeouts for locking screens in desktop/laptop
  lockTimeout = if dangerousAlone then 60 else 300;
  dpmsTimeout = lockTimeout * 2;
})
