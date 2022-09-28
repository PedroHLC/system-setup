# The top lambda and it super set of parameters.
{ config, lib, pkgs, nix-gaming, zfs-staging, ... }:

# NixOS-defined options
{
  # For debugging ZFS
  boot.crashDump.enable = true;

  # Nix package-management settings.
  nix = {
    settings = {
      # Unofficial binary caches.
      substituters = [
        "https://nix-gaming.cachix.org"
        # "http://nix-cache.pedrohlc.com"
      ];
      trusted-public-keys = [
        "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
        "nix-cache.pedrohlc.com:LffNbH46uPoFetK4OPmKWiBOssUG3JA0fXNx98wVK34="
      ];
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
  hardware.cpu.intel.updateMicrocode = true;
  hardware.cpu.amd.updateMicrocode = true;

  # Filesytems settings.
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = false;

  # Temporarily move to ZFS-staging for 5.19
  boot.zfs.enableUnstable = true;

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

    # https://github.com/NixOS/nixpkgs/issues/35681#issuecomment-370202008
    "systemd.gpt_auto=0"
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

    # Disable non-NetworkManager.
    useDHCP = false;
  };

  # LAN discovery.
  services.avahi = {
    enable = true;
    nssmdns = true;
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

  # XDG-Portal (for dialogs & screensharing).
  xdg.portal = {
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-kde
    ];
  };

  # XWayland keyboard layout.
  services.xserver.layout = "br";

  # Console keyboard layout.
  console.keyMap = "br-abnt2";

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
    ALSOFT_DRIVERS = "pipewire";
    GAMEMODERUNEXEC = "WINEFSYNC=1 PROTON_WINEDBG_DISABLE=1 DXVK_LOG_PATH=none DXVK_HUD=compiler WINEDEBUG=-all DXVK_LOG_LEVEL=none";
  };

  # Autologin.
  services.getty = {
    loginProgram = "${pkgs.bash}/bin/sh";
    loginOptions = toString pkgs.login-program;
    extraArgs = [ "--skip-login" ];
  };

  # List packages.
  environment.systemPackages = with pkgs; [
    # Desktop apps
    acpi
    alacritty
    audacious
    brightnessctl
    discord
    element-desktop-wayland
    ffmpegthumbnailer
    firefox-wayland
    fx_cast_bridge
    keybase-gui
    libinput
    libinput-gestures
    libsForQt5.kio # Fixes "Unknown protocol 'file'."
    lm_sensors
    lxmenu-data # For lxqt apps' "Open with" dialogs
    lxqt.lxqt-sudo
    lxqt.pavucontrol-qt
    lxqt.pcmanfm-qt
    mpv
    nomacs
    obs-studio-wrap
    osdlyrics
    pamixer # for avizo
    qbittorrent
    slack
    space-cadet-pinball
    spotify
    streamlink
    tdesktop
    ungoogled-chromium
    usbutils
    waypipe
    wpsoffice
    xarchiver
    xdg-utils
    zoom-us

    # My scripts
    firefox-gate
    nowl
    wayland-env

    # Development apps
    awscli2 # AWS
    dbeaver
    deno # Front-dev
    eksctl # AWS
    elixir # Elixir-dev
    elmPackages.elm-format # Elm-dev
    gdb # more precious then gcc
    gh
    gnumake
    heroku
    k9s # Kubernets
    kubectl # Kubernets
    kubernetes-helm # HELM
    logstalgia # Chaotic
    nixpkgs-fmt # Nix
    nixpkgs-review # Nix
    nodejs # Front-dev
    rebar3 # Elixir-dev
    shellcheck # Bash-dev
    shfmt # Bash-dev
    sublime4
    yarn # Front-dev

    # Less used
    adbfs-rootless
    bluez-tools
    helvum
    libnotify
    libva-utils
    ripgrep
    vulkan-caps-viewer

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
    wine-ge
    vulkan-tools
    winetricks

    # GI
    jq
    xdelta
  ];

  # The base GUI toolkit in my setup.
  qt5 = {
    enable = true;
    platformTheme = "kde";
  };

  # Special apps (requires more than their package to work).
  programs.adb.enable = true;
  programs.gamemode.enable = true;
  programs.steam.enable = true;

  # Fix swaylock (nixpkgs issue 158025)
  security.pam.services.swaylock = { };

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfigsOverlay = final: prev: {
        # Obs with plugins
        obs-studio-wrap = final.wrapOBS.override { obs-studio = final.obs-studio; } {
          plugins = with final.obs-studio-plugins; [
            obs-gstreamer
            obs-pipewire-audio-capture
            obs-vkcapture
            wlrobs
          ];
        };

        # Script to force XWayland (in case something catches fire).
        nowl = final.callPackage ../shared/pkgs/nowl.nix { };

        # Script to open my encrypted firefox profile.
        firefox-gate = final.callPackage ../shared/pkgs/firefox-gate.nix { };

        # Script for swaylock with GIFs on background (requires configuration in sway).
        my-wscreensaver = final.callPackage ../shared/pkgs/my-wscreensaver.nix { };

        # Environment to properly (and force) use wayland.
        wayland-env = final.callPackage ../shared/pkgs/wayland-env.nix { };

        # Script required for autologin (per TTYs).
        login-program = final.callPackage ../shared/pkgs/login-program.nix { };

        # Audacious rice
        audacious-skin-winamp-classic = final.callPackage ../shared/pkgs/audacious-skin-winamp-classic.nix { };

        # Anime4K shaders
        anime4k = final.callPackage ../shared/pkgs/anime4k.nix { };

        # Allow bluetooth management easily in sway
        fzf-bluetooth = final.callPackage ../shared/pkgs/fzf-bluetooth.nix { };

        # Add OpenAsar to Discord and fix clicking in links for firefox
        discord = prev.discord.override { withOpenASAR = true; nss = final.nss_latest; };

        # Add pipewire-output to Audacious
        audacious = import ../shared/lib/audacious-overlay.nix final prev;

        # Focusire mono-mic
        pw-focusrite-mono-input = final.callPackage ../shared/pkgs/pw-focusrite-mono-input.nix { };

        # Add the Wine-GE for any machine
        wine-ge = nix-gaming.packages.x86_64-linux.wine-ge;

        # Bump zfs-unstable in linux-lqx
        linuxPackages_lqx = prev.linuxPackages_lqx.extend (lpFinal: lpPrev: {
          zfsUnstable = lpPrev.zfsUnstable.overrideAttrs (oldAttrs: {
            src = zfs-staging;
            version = "2.1.6-staging";
            kernelCompatible = lpFinal.kernelOlder "5.20";
            passthru.latestCompatibleLinuxPackages = final.linuxKernel.packages.linuxPackages_5_19;
            meta.broken = false;
          });
        });
      };
    in
    [ thisConfigsOverlay ];

  # Enable services (automatically includes their apps' packages).
  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.keybase.enable = true;
  services.kbfs.enable = true;
  services.tumbler.enable = true;
  services.minidlna = {
    enable = true;
    settings = {
      media_dir = [ "/home/upnp-shared/Media" ];
      inotify = "yes";
    };
  };
  services.dbus = {
    enable = true;
    packages = with pkgs; [ osdlyrics ];
  };

  # Fonts.
  fonts = {
    enableDefaultFonts = true; # Those fonts you expect every distro to have.
    fonts = with pkgs; [
      borg-sans-mono
      cantarell-fonts
      fira
      fira-code
      fira-code-symbols
      font-awesome_4
      font-awesome_5
      noto-fonts
      noto-fonts-cjk
      open-fonts
      roboto
      ubuntu_font_family
    ];
    fontconfig = {
      cache32Bit = true;
      defaultFonts = {
        serif = [ "Noto Serif" ];
        sansSerif = [ "Roboto" ];
        monospace = [ "Fira Code" ];
      };
    };
  };

  # For out-of-box gaming with Heroic Game Launcher
  services.flatpak.enable = true;

  # Virtualisation / Containerization.
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };
  };

  # For development, but disabled to start service on-demand
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql; # always the latest
  };
  systemd.services.postgresql.wantedBy = lib.mkForce [ ]; # don't start with system

  # Creates a second boot entry with LTS kernel and stable ZFS
  specialisation.safe.configuration = {
    system.nixos.tags = [ "lts" "zfs-stable" ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    boot.zfs.enableUnstable = lib.mkForce false;
  };

  # Change the allocator in hope it will save me 5 ms everyday.
  # Bug: jemalloc 5.2.4 seems to break spotify and discord, crashes firefox when exiting and freezes TabNine.
  # environment.memoryAllocator.provider = "jemalloc";

  # Hardcodes some address resolving
  networking.extraHosts =
    ''
      # - My machines

      10.100.0.1 vps-lab.vpn
      10.100.0.2 desktop.vpn
      10.100.0.3 laptop.vpn
      192.168.100.194 desktop.family-lan
      192.168.100.136 laptop.family-lan
      
      # - Required to play GenshinImpact on Linux without banning.

      # Genshin logging servers (do not remove!)
      0.0.0.0 overseauspider.yuanshen.com
      0.0.0.0 log-upload-os.hoyoverse.com

      # Optional Unity proxy/cdn servers
      0.0.0.0 prd-lender.cdp.internal.unity3d.com
      0.0.0.0 thind-prd-knob.data.ie.unity3d.com
      0.0.0.0 thind-gke-usc.prd.data.corp.unity3d.com
      0.0.0.0 cdp.cloud.unity3d.com
      0.0.0.0 remote-config-proxy-prd.uca.cloud.unity3d.com
    '';
}
