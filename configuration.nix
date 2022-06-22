# The top lambda and it super set of parameters.
{ config, lib, pkgs, nix-gaming, ... }:

# NixOS-defined options
{
  # Nix package-management settings.
  nix = {
    # Enable flakes and newer CLI features
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations
    '';
    settings = {
      # Allow my user to use nix
      trusted-users = [ "root" "pedrohlc" ];

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
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  # Filesytems settings.
  boot.supportedFilesystems = [ "zfs" ];
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
      extraGroups = [ "wheel" "video" "networkmanager" "rtkit" ];
      shell = pkgs.dash;
      openssh.authorizedKeys.keys = [
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+XO1v27sZQO2yV8q2AfYS/I/l9pHK33a4IjjrNDhV+YBlLbR2iB+L5iNu7x8tKDXYscynxJPHB3vWwerZXOh35SXdh5TE9Lez02Ck466fJnTjNxX63FvppXmMx8HaVYzymojDi+xTXMO4DxNFFrJTUIagWs8WNxEbYdGAaIKRQHB0ZWMSsyaY2XkR9RkV3I9QwKNrTnkC5h8bVn63LvTuORlTvY/Iu202M2toxOKWDQ5qdSrLfNaPl7kxWUVTCpyZ8Hza75sH3SB3/m8Queeq+E48nqjL7s9ZyO1TGf6ojaf2EGfx6H8jFwycXUD2QNLvsZcWmamyLPNbHY63jjOb pedrohlc@desktop"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/vOidQLdDQ+vCet6trM5RRZJ6xujf4YJOve4vAdzBCUk30JQ3g3Kbkkdq3AWmvwRpUEkMxMiIGweiFXphvfIJvyHdSXaFoury8Va1n6I5bUS7ntaQI5R2SKBh2WHW1q/tzP5W7UxS4DwYg3kEXZp0V7sqTbw+4t8ctcS51Wam6LuUidqikukYQwKoz9DI9q0B3+U6qTl21jXwpZtqpvcTeC3ElqrkhgN4h4hNgWyjHGmfiB9NpGwPhwyfreRRiyVPXgGU9M9vI7D95ga+6eDS04aQph/MrEWgAh8jDvPzJW4PIQumhTtJdw/8v+vPqPM6+aAlwDoEKnZg1INsBb4R pedrohlc@poco-x3"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDe+j0odZ7Mk0p8Q9lv0HWFt62ZW6uN4wi+pp7YD8BquU8cKYlh1yk5kQxzwhEpsrIgyiOYU5CxYWkdblh+h/oLBk7seCzYF+ZZnhR5AJdbUvz8FNPbDqd81tphjntRphNArYVgdpIz0pwvYz9yvDwNXaaPfJuLTIecmIM1PaVnQOTKR6zNhwWad9bXWr4NdS2LN5rl8Yg083BKu36kcdnj8bQi7viNhbpHrwYhDUiMuysUdAd/atNJGwyFehmRckhC/Jv65eJtwR/asXTsEB9KaRAqnuThAR9bGwlMdHP/zZOhB3Bb/M+HTafOlVvBv30iJXg426EUpoMg+X0C0ZOM+wddSDRTmf2z6m/tOxguG0DNwfug1lWjZUlLeevkauBywKo1TlqQEZ9BDFgI/J34YGELJV6hUYe+rQfzcTZwQ9nLx2bcZA877Sf7sAu4ajw+p2Vcz4gypwpdT6vNfDt15w9HKJM/PCAl9Y2OxXOqogrwL1zG9P7tX5adiXp3QW8= pedrohlc@laptop"
      ];
    };
    melinapn = {
      isNormalUser = true;
      extraGroups = [ "video" "networkmanager" ];
    };
  };
  security.sudo.wheelNeedsPassword = false;

  # Autologin.
  services.getty = {
    loginProgram = "${pkgs.bash}/bin/sh";
    loginOptions = toString pkgs.login-program;
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
    audacious
    brightnessctl
    btop
    busyboxWithoutAppletSymlinks
    discord
    element-desktop-wayland
    ffmpegthumbnailer
    file
    firefox-gate
    firefox-wayland
    fzf
    fx_cast_bridge
    git
    google-authenticator
    google-chrome-beta
    keybase-gui
    killall
    libinput
    libinput-gestures
    lm_sensors
    lxmenu-data # For lxqt apps' "Open with" dialogs
    lxqt.lxqt-sudo
    lxqt.pavucontrol-qt
    lxqt.pcmanfm-qt
    mosh
    mpv
    nomacs
    nowl
    obs-studio-wrap
    p7zip
    pamixer # for avizo
    pciutils
    qbittorrent
    slack
    space-cadet-pinball
    spotify
    sshfs-fuse
    streamlink
    tdesktop
    unrar
    unzip
    usbutils
    uutils-coreutils
    waypipe
    wireguard-tools
    wget
    wpsoffice
    xarchiver
    xdg_utils
    zoom-us

    # Development apps
    deno
    elmPackages.elm-format
    gdb # more precious then gcc
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
    libva-utils
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
  programs.command-not-found.enable = false;
  programs.dconf.enable = true;
  programs.fish = {
    enable = true;
    vendor = {
      config.enable = true;
      completions.enable = true;
    };
  };
  programs.gamemode.enable = true;
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true; # So I can use GPG through SSH
    pinentryFlavor = "tty";
  };
  programs.steam.enable = true;
  programs.tmux = {
    enable = true;
    clock24 = true;
  };

  # Neovim to rule them all.
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };
  environment.variables.EDITOR = "nvim";

  # Fix swaylock (nixpkgs issue 158025)
  security.pam.services.swaylock = { };

  # Override packages' settings.
  nixpkgs.config.packageOverrides = pkgs: {
    # Steam with gaming-stuff
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [ gamemode mangohud ];
    };

    # Obs with plugins
    obs-studio-wrap = pkgs.wrapOBS.override { obs-studio = pkgs.obs-studio; } {
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
        obs-vkcapture
      ];
    };

    # Script to force XWayland (in case something catches fire).
    nowl = pkgs.callPackage ./tools/nowl.nix { };

    # Script to open my encrypted firefox profile.
    firefox-gate = pkgs.callPackage ./tools/firefox-gate.nix { };

    # Script for swaylock with GIFs on background (requires configuration in sway).
    my-wscreensaver = pkgs.callPackage ./tools/my-wscreensaver.nix { };

    # Allow uutils to replace GNU coreutils.
    uutils-coreutils = pkgs.uutils-coreutils.override { prefix = ""; };

    # Environment to properly (and force) use wayland.
    wayland-env = pkgs.callPackage ./tools/wayland-env.nix { };

    # Script required for autologin (per TTYs).
    login-program = pkgs.callPackage ./tools/login-program.nix { };

    # Audacious rice
    audacious-skin-winamp-classic = pkgs.callPackage ./tools/audacious-skin-winamp-classic.nix { };

    # Busybox without applets
    busyboxWithoutAppletSymlinks = pkgs.busybox.override {
      enableAppletSymlinks = false;
    };
  };

  # Enable services (automatically includes their apps' packages).
  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.keybase.enable = true;
  services.kbfs.enable = true;
  services.ntp.enable = true;
  services.openssh = {
    # TODO: Use openssh_hpn
    enable = true;
    forwardX11 = true;
    permitRootLogin = "no";
  };
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

  # Patch some packages
  nixpkgs.overlays = [
    (self: super: {
      linuxPackages_zen = super.linuxPackages_zen.extend
        (lpSelf: lpSuper: {
          zfsUnstable = lpSuper.zfsUnstable.overrideAttrs (attrs: {
            src = self.fetchFromGitHub {
              owner = "openzfs";
              repo = "zfs";
              sha256 = "111MGFx/Nb2UoJljL/8bHbtHm0/U2aBvdymcSXsIGvg=";
              rev = "zfs-2.1.5"; #zfs-2.1.5-hutter
            };
            meta.broken = false;
          });
        });
    })
  ];

  # Creates a second boot entry with LTS kernel and stable ZFS
  specialisation.safe.configuration = {
    system.nixos.tags = [ "lts" "zfs-stable" ];
    boot.kernelPackages = pkgs.linuxPackages;
    boot.zfs.enableUnstable = false;
  };

  # Change the allocator in hope it will save me 5 ms everyday.
  # Bug: jemalloc 5.2.4 seems to break spotify and discord, crashes firefox when exiting and freezes TabNine.
  # environment.memoryAllocator.provider = "jemalloc";

  # Hardcodes some address resolving
  networking.extraHosts =
    ''
      10.100.0.1 desktop.vpn
      192.168.100.194 desktop.local
      
      # - Required to play GenshinImpact on Linux without banning.

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
