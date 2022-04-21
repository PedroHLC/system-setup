# The top lambda and it super set of parameters.
{ nix-gaming, config, lib, pkgs, ... }:

# My user-named values.
let
  # Script to open my encrypted firefox profile.
  firefox-gate = (import ./tools/firefox-gate.nix) pkgs;

  # Script required for autologin (per TTYs).
  loginScript = (import ./tools/login-program.nix) pkgs;

  # Script for swaylock with GIFs on background (requires configuration in sway).
  my-wscreensaver = (import ./tools/my-wscreensaver.nix) pkgs;

  # Script to force XWayland (in case something catches fire).
  nowl = (import ./tools/nowl.nix) pkgs;

  # Allow uutils to replace GNU coreutils.
  uutils-coreutils = pkgs.uutils-coreutils.override { prefix = ""; };

in
# NixOS-defined options
{
  # Nix package-management settings.
  nix = {
    # Enable flakes and newer CLI features
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      # Allow my user to use nix
      trusted-users = [ "root" "pedrohlc" ];

      # Unofficial binary caches.
      substituters = [ "https://nix-gaming.cachix.org" ];
      trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      editor = false;
    };
    timeout = 1;
    efi.canTouchEfiVariables = true;
  };

  # Microcode updates.
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  # Kernel versions (I prefer Zen, when it's not broken for ZFS).
  boot.kernelPackages =
    #config.boot.zfs.package.latestCompatibleLinuxPackages;
    pkgs.linuxPackages_zen;

  # Filesytems settings.
  boot.supportedFilesystems = [ "zfs" "ntfs" ];
  boot.zfs.requestEncryptionCredentials = false;

  # I like /tmp on RAM.
  boot.tmpOnTmpfs = true;
  boot.tmpOnTmpfsSize = "100%";

  # Kernel Params
  boot.kernelParams = [
    # Disable all mitigations
    "mitigations=off"
    "no_stf_barrier"
    "noibpb"
    "noibrs"
    "nopti"
    "tsx=on"

    # Laptops and dekstops don't need Watchdog
    "nowatchdog"
  ];
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1; # Enable ALL SysRq shortcuts
  };


  # Network (NetworkManager).
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    # "enp2s0" instead of "eth0". 
    usePredictableInterfaceNames = true;

    # Disable non-NetworkManager.
    useDHCP = false;

    # Disable the firewall.
    firewall.enable = false;
  };

  # LAN discovery.
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  # Default time zone.
  time.timeZone = "America/Sao_Paulo";

  # Internationalisation.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    supportedLocales = [ "en_GB.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" ];
    extraLocaleSettings = {
      LC_TIME = "pt_BR.UTF-8";
    };
  };
  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  # Bluetooth.
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # GPU
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Enable the SwayWM.
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      swaylock
      swayidle
      wl-clipboard
      libinput
      libinput-gestures
    ];
    extraSessionCommands = ''
      # Force wayland overall.
      export BEMENU_BACKEND='wayland'
      export CLUTTER_BACKEND='wayland'
      export ECORE_EVAS_ENGINE='wayland_egl'
      export ELM_ENGINE='wayland_egl'
      export GDK_BACKEND='wayland'
      export MOZ_ENABLE_WAYLAND=1
      export QT_AUTO_SCREEN_SCALE_FACTOR=0
      export QT_QPA_PLATFORM='wayland-egl'
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export SAL_USE_VCLPLUGIN='gtk3'
      export SDL_VIDEODRIVER='wayland'
      export _JAVA_AWT_WM_NONREPARENTING=1
      export NIXOS_OZONE_WL=1
      
      # KDE/Plasma platform for Qt apps.
      export QT_QPA_PLATFORMTHEME='kde'
      export QT_PLATFORM_PLUGIN='kde'
      export QT_PLATFORMTHEME='kde'
    '';
  };

  # XDG-Portal (for dialogs & screensharing).
  xdg.portal = {
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  # XWayland keyboard layout.
  services.xserver.layout = "br";

  # Sound (pipewire & wireplumber).
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    media-session.enable = false;
    systemWide = false;

    wireplumber.enable = true;
  };
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true; # OpenAL likes it, but my pipewire is not configure to rt.
  environment.variables = {
    AE_SINK = "ALSA"; # For Kodi, better latency/volume under pw.
    SDL_AUDIODRIVER = "pipewire";
    ALSOFT_DRIVERS = "alsa"; # Fixes Telegram, better latency under pw. (waiting stable release of pipewire driver).
    GAMEMODERUNEXEC = "mangohud WINEFSYNC=1 PROTON_WINEDBG_DISABLE=1 DXVK_LOG_PATH=none DXVK_HUD=compiler ALSOFT_DRIVERS=alsa";
  };

  # User accounts.
  users.users = {
    pedrohlc = {
      isNormalUser = true;
      uid = 1001;
      extraGroups = [ "wheel" "video" "networkmanager" "rtkit" ];
      shell = pkgs.dash;
    };
    melinapn = {
      isNormalUser = true;
      uid = 1002;
      extraGroups = [ "video" "networkmanager" ];
    };
  };
  security.sudo.wheelNeedsPassword = false;

  # Autologin.
  services.getty = {
    loginProgram = "${pkgs.bash}/bin/sh";
    loginOptions = toString loginScript;
    extraArgs = [ "--skip-login" ];
  };

  # List packages.
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Desktop apps
    acpi
    alacritty
    android-tools
    aria2
    avizo
    brightnessctl
    btop
    cachix
    discord
    ffmpegthumbnailer
    file
    firefox-gate
    firefox-wayland
    fzf
    #fx_cast_bridge # broken
    git
    gnome-network-displays
    gnome.zenity
    google-authenticator
    google-chrome-beta
    grim
    i3status-rust
    killall
    lm_sensors
    lxqt.pavucontrol-qt
    lxqt.pcmanfm-qt
    mosh
    mpv
    my-wscreensaver
    nomacs
    nowl
    p7zip
    pamixer # for avizo
    pciutils
    qbittorrent
    slack
    slurp
    spotify
    streamlink
    sway-launcher-desktop
    swaynotificationcenter
    tdesktop
    tmux
    unrar
    unzip
    usbutils
    uutils-coreutils
    wget
    wpsoffice
    xarchiver
    xdg_utils
    zoom-us

    # Development apps
    deno
    elmPackages.elm-format
    gnumake
    nixpkgs-fmt
    nodejs
    shellcheck
    shfmt
    sublime4
    yarn

    # Less used
    adbfs-rootless
    helvum
    neofetch
    nix-index
    nmap
    traceroute

    # Desktop themes
    breeze-gtk
    breeze-icons
    breeze-qt5
    oxygen-icons5
    qqc2-breeze-style
    vimix-icon-theme

    # Gaming
    mangohud
    mesa-demos
    nix-gaming.packages.x86_64-linux.wine-tkg
    vulkan-tools
    winetricks

    # GI
    jq
    xdelta
  ];

  # Special apps (requires more than their package to work).
  programs.dconf.enable = true;
  programs.fish.enable = true;
  programs.gamemode.enable = true;
  programs.steam.enable = true;

  # Neovim to rule them all.
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
  environment.variables.EDITOR = "nvim";

  # Override packages' settings.
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [ gamemode mangohud ];
    };
  };

  # Enable services (automatically includes their apps' packages).
  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.ntp.enable = true;
  services.sshd.enable = true; # TODO: Use openssh_hpn
  services.tumbler.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.minidlna = {
    enable = true;
    mediaDirs = [ "/home/upnp-shared/Media" ];
  };

  # Enable google-authenticator
  security.pam.services.sshd.googleAuthenticator.enable = true;

  # We are anxiously waiting for PR 122547
  #services.dbus-broker.enable = true;

  # SSH requires gnupg that requires SUID.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Fonts.
  fonts.fonts = with pkgs; [
    borg-sans-mono

    cantarell-fonts
    fira
    fira-code
    fira-code-symbols
    fira-mono
    font-awesome_4
    font-awesome_5
    freefont_ttf
    google-fonts
    liberation_ttf
    noto-fonts
    ubuntu_font_family
  ];


  # Virtualisation / Containerization.
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true; # Podman provides docker.
    };
  };

  # Required to play GenshinImpact on Linux without banning.
  networking.extraHosts =
    ''
      # Genshin logging servers (do not remove!)
      0.0.0.0 log-upload-os.mihoyo.com
      0.0.0.0 overseauspider.yuanshen.com

      # Optional Unity proxy/cdn servers
      0.0.0.0 prd-lender.cdp.internal.unity3d.com
      0.0.0.0 thind-prd-knob.data.ie.unity3d.com
      0.0.0.0 thind-gke-usc.prd.data.corp.unity3d.com
      0.0.0.0 cdp.cloud.unity3d.com
      0.0.0.0 remote-config-proxy-prd.uca.cloud.unity3d.com
    '';

  # Automatically removes NixOS' older builds.
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Auto-upgrade NixOS.
  system.autoUpgrade.enable = true;
}
