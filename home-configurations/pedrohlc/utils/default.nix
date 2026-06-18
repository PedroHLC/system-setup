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
, ...
}@specs:
{ config, lib, pkgs, ssot, osConfig ? null, usingNouveau ? true, ... }@scope:
self:
{
  inherit battery cpuSensor dangerousAlone dlnaName gitKey gpuSensor mainNetworkInterface nvmeSensors seat ups;
  inherit config pkgs osConfig usingNouveau;
  inherit (scope) flakes;
  inherit (lib.strings) optionalString concatStringsSep;
  inherit (lib.trivial) importJSON;
  inherit (lib.debug) traceVal;
  inherit (lib.hm) dag;
  inherit (scope.flakes) ullib pedrochrome-css;
} // (lib // ssot // rec {
  pseudoPkgs = import ./derivations.nix self;

  # Expand specs
  hasBattery = battery != null;
  hasUPS = ups != null;
  hasGitKey = gitKey != null;
  hasSeat = seat != null;
  hasLinuxSeat = hasSeat && isLinux;
  hasAppleSeat = hasSeat && isMacOS;
  hasTouchpad = touchpad != null;
  hostOS = specs.hostOS or (if osConfig != null then "nixos" else throw "Unsupported system");
  isNixOS = hostOS == "nixos";
  isMacOS = hostOS == "macos";
  isLinux = !isMacOS;

  # Expand seat specs
  autoLogin = seat.autoLogin or hasLinuxSeat;
  displayBrightness = seat.displayBrightness or false;
  kvm = seat.kvm or specs.kvm or null;
  nvidiaBad = nvidiaPrime && !usingNouveau;
  nvidiaPrime = seat.nvidiaPrime or false;
  sunshine = seat.sunshine or false;
  ctrlNearSpaceKeyMap = hasLinuxSeat && (seat.ctrlNearSpaceKeyMap or false);
  touchpad = if hasSeat then (seat.touchpad or false) else null;

  macCtrl = if ctrlNearSpaceKeyMap then "Mod1" else "Control";
  macCmd = if ctrlNearSpaceKeyMap then "Control" else "Mod1";

  bin = rec {
    # Preferred executables
    browser = "${pseudoPkgs.firefox-gate}/bin/firefox-gate";
    editor = "${pkgs.zed-editor}/bin/zeditor";
    terminal = lib.getExe config.programs.alacritty.package;

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
    herdr = lib.getExe pkgs.herdr;
    tmux = lib.getExe pkgs.tmux;
    fish = lib.getExe config.programs.fish.package;
    fzf = lib.getExe pkgs.fzf;
    systemctl = "${pkgs.systemd}/bin/systemctl";
    bluetoothctl = "${pkgs.bluez}/bin/bluetoothctl";
    nmcli = "${pkgs.networkmanager}/bin/nmcli";
    check-sha256 = "${pseudoPkgs.check-sha256}/bin/check-sha256";
    notify = "${pkgs.libnotify}/bin/notify-send";

    copy = if isMacOS then "pbcopy" else "${pkgs.wl-clipboard}/bin/wl-copy";
    paste = if isMacOS then "pbpaste" else "${pkgs.wl-clipboard}/bin/wl-paste";

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
  firefoxSuffix = "-devedition";

  # per-GPU values
  videoAcceleration = if nvidiaBad then "nvdec-copy" else "vaapi";

  # To help with Audacious configs
  audaciousConfigGenerator = pkgs.callPackage ../../../packages/audacious-config-generator.nix { };

  # Different timeouts for locking screens in desktop/xbox
  lockTimeout = if dangerousAlone then 60 else 300;
  dpmsTimeout = lockTimeout * 2;
})
