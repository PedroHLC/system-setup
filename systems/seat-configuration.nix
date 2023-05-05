# The top lambda and it super set of parameters.
{ lib, pkgs, ssot, flakeInputs, ... }: with ssot;

# NixOS-defined options
{
  # Latest nix on phisically-accessible machines
  nix.package = pkgs.nixVersions.unstable;

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

  # ZFS being out-of-tree is super head-aches
  boot.zfs.enableUnstable = true;
  boot.kernelPackages = pkgs.linuxPackages_lqx; # pkgs.callPackage ../shared/pkgs/pinned-linux-lqx.nix { };

  # Kernel Params
  boot.kernelParams = [
    # Disable all mitigations
    "mitigations=off"
    "nopti"
    "tsx=on"

    # Laptops and dekstops don't need Watchdog
    "nowatchdog"

    # https://github.com/NixOS/nixpkgs/issues/35681#issuecomment-370202008
    "systemd.gpt_auto=0"

    # https://www.phoronix.com/news/Linux-Splitlock-Hurts-Gaming
    "split_lock_detect=off"
  ];
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1; # Enable ALL SysRq shortcuts
    "vm.max_map_count" = 2147483642; # helps with Wine ESYNC/FSYNC
  };

  # ZFS-based impermanence
  chaotic.zfs-impermanence-on-shutdown = {
    enable = true;
    volume = "zroot/ROOT/empty";
    snapshot = "start";
  };

  # Network (NetworkManager).
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      dns = "systemd-resolved";
    };

    # Disable non-NetworkManager.
    useDHCP = false;
  };

  # DNS
  services.resolved = {
    enable = true;
    fallbackDns = [ vpn.zeta.v4 vpn.zeta.v6 ];
  };

  # LAN discovery.
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  # Bluetooth.
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.joycond.enable = true;

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
    systemWide = false;

    wireplumber.enable = true;
  };
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true; # OpenAL likes it, but my pipewire is not configure to rt.
  environment.variables.AE_SINK = "ALSA"; # For Kodi, better latency/volume under pw.
  environment.variables.SDL_AUDIODRIVER = "pipewire";
  environment.variables.ALSOFT_DRIVERS = "pipewire";


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
    btop
    brightnessctl
    discord
    element-desktop-wayland
    ffmpegthumbnailer
    firefox-wayland
    fx_cast_bridge
    google-chrome
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
    obs-studio-wrapped
    osdlyrics
    pamixer # for avizo
    qbittorrent
    slack
    space-cadet-pinball
    spotify
    streamlink
    tdesktop
    usbutils
    waypipe
    xarchiver
    xdg-utils
    zoom-us

    # My scripts
    firefox-gate
    my-wscreensaver
    nowl
    wayland-env

    # Development apps
    awscli2 # AWS
    bind.dnsutils # "dig"
    dbeaver
    deno # Front-dev
    eksctl # AWS
    elixir_1_14 # Elixir-dev, I need it here for "mix format"
    elmPackages.elm-format # Elm-dev
    gcc # C-dev but using it for Elixir-dev, since rebar3 needs it to build iconv
    gdb # more precious then gcc
    gh
    gnumake
    heroku
    inotify-tools # watching files
    k9s # Kubernets
    kubectl # Kubernets
    kubernetes-helm-wrapped # HELM
    logstalgia # Chaotic
    nixpkgs-fmt # Nix
    nixpkgs-review # Nix
    nodejs # Front-dev
    python3Minimal
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

    # Office-stuff
    # calligra (struggling with qtwebkit)
    inkscape
    gimp
    texlive.combined.scheme-medium
    wpsoffice

    # Desktop themes
    breeze-gtk
    breeze-icons
    breeze-qt5
    oxygen-icons5
    qqc2-breeze-style
    vimix-icon-theme

    # Gaming
    mangohud_git
    mesa-demos
    wine-staging
    vulkan-tools
    winetricks

    # GI
    jq
    xdelta

    # KVM
    input-leap_git
    waynergy_git
  ];

  # The base GUI toolkit in my setup.
  qt = {
    enable = true;
    platformTheme = "kde";
  };

  # Special apps (requires more than their package to work).
  programs.adb.enable = true;
  programs.gamemode.enable = true;
  programs.steam.enable = true;
  chaotic.gamescope = {
    enable = true;
    args = [ "--rt" ];
    package = pkgs.gamescope_git;
  };

  # Fix swaylock (nixpkgs issue 158025)
  security.pam.services.swaylock = { };
  security.pam.services.swaylock-plugin = { };

  # Other preferences
  environment.variables.GAMEMODERUNEXEC = "WINEFSYNC=1 PROTON_WINEDBG_DISABLE=1 DXVK_LOG_PATH=none DXVK_HUD=compiler WINEDEBUG=-all DXVK_LOG_LEVEL=none RADV_PERFTEST=rt,ngg_streamout";
  environment.variables.WINEPREFIX = "/dev/null";
  environment.variables.GTK_THEME = "Breeze-Dark";

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfigsOverlay = final: prev: {
        # Obs with plugins
        obs-studio-wrapped = final.wrapOBS.override { inherit (final) obs-studio; } {
          plugins = with final.obs-studio-plugins; [
            obs-gstreamer
            obs-pipewire-audio-capture
            obs-vaapi
            obs-vkcapture
            wlrobs
          ];
        };

        # Helm with plugins
        kubernetes-helm-wrapped = final.wrapHelm
          (prev.kubernetes-helm.overrideDerivation (oa: {
            patches = [
              (final.fetchpatch {
                url = "https://github.com/PedroHLC/helm/commit/0144b70c0ef66877637c37a4211cb430f1e61e33.patch";
                hash = "sha256-2BHv8QvVijlN7UVC6zoLsTI1o7HQlafuDeoGb2WpVGw=";
              })
            ] ++ oa.patches;
          }))
          { plugins = with final.kubernetes-helmPlugins; [ helm-diff ]; };

        # Script to force XWayland (in case something catches fire).
        nowl = final.callPackage ../shared/pkgs/nowl.nix { };

        # Script to open my encrypted firefox profile.
        firefox-gate = final.callPackage ../shared/pkgs/firefox-gate.nix { };

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
        discord = prev.discord.override {
          withOpenASAR = true;
          nss = final.nss_latest;
        };

        # Focusire mono-mic
        pw-focusrite-mono-input = final.callPackage ../shared/pkgs/pw-focusrite-mono-input.nix { };

        # PokeMMO mutable launcher
        pokemmo-launcher = final.callPackage ../shared/pkgs/pokemmo-launcher.nix { };

        # swaylock with GIFs
        my-wscreensaver = final.callPackage ../shared/pkgs/my-wscreensaver.nix { };
      };
    in
    [ thisConfigsOverlay ];

  # Enable services (automatically includes their apps' packages).
  services.fwupd.enable = true;
  services.gvfs.enable = true;
  services.keybase.enable = true;
  services.kbfs.enable = true;
  services.tumbler.enable = true;
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
      droid-sans-mono-nerdfont
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

  # Allow to cross-compile to aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Virtualisation / Containerization.
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };

    storage.options.zfs = {
      fsname = "zroot/containers";
      mountopt = "nodev";
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

  # Change my MOUSE4 and MOUSE5 behavior (found it with "evtest")
  # - on both Dongle and Bluetooth mode
  services.udev.extraHwdb = ''
    evdev:name:Corsair CORSAIR KATAR PRO Wireless Gaming Dongle:*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_90005=btn_forward
      KEYBOARD_KEY_90004=btn_back
    evdev:name:KATAR PRO Wireless Mouse:*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_90005=btn_forward
      KEYBOARD_KEY_90004=btn_back
  '';

  # Persistent files
  environment.persistence."/var/persistent" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/nixos"
      "/etc/ssh"
      "/var/lib/bluetooth"
      "/var/lib/containers"
      "/var/lib/cups"
      "/var/lib/flatpak"
      { directory = "/var/lib/iwd"; mode = "u=rwx,g=,o="; }
      "/var/lib/systemd"
      "/var/lib/upower"
    ];
    files = [
      "/etc/machine-id"
    ];
    users.root = {
      home = "/root";
      directories = [
        ".android" # adb keys
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
      ];
    };
    users.pedrohlc = {
      directories = [
        ".android" # adb keys
        { directory = ".aws"; mode = "0700"; }
        ".local/share/containers"
        ".config/asciinema"
        ".config/btop"
        { directory = ".config/cachix"; mode = "0700"; }
        ".config/discord"
        ".config/Element"
        { directory = ".config/Keybase"; mode = "0700"; }
        { directory = ".config/keybase"; mode = "0700"; }
        ".config/nvim"
        ".config/obs-studio"
        ".config/osdlyrics"
        ".config/qBittorrent"
        ".config/spotify"
        ".config/sublime-text"
        ".config/TabNine"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".kube"; mode = "0700"; }
        ".local/share/DBeaverData"
        ".local/share/fish"
        ".local/share/heroku"
        { directory = ".local/share/keybase"; mode = "0700"; }
        ".local/share/qBittorrent"
        ".local/share/Steam"
        ".local/share/TelegramDesktop"
        ".local/share/Terraria"
        { directory = ".secrets"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        ".var/app"
        ".zoom"
        "Documents"
        "Downloads"
        "Projects"
        "Pictures"
        "Videos"
      ];
      files = [
        ".cache/keybasekeybase.app.serverConfig"
        ".google_authenticator"
        ".netrc"
      ];
    };
  };

  # Not important but persistent files
  environment.persistence."/var/residues" = {
    hideMounts = true;
    directories = [
      "/var/cache"
      "/var/log"
      "/var/spool"
    ];

    users.pedrohlc = {
      directories = [
        ".cache/deno"
        ".cache/keybase"
        ".cache/mesa_shader_cache"
        ".cache/mozilla"
        ".cache/nix-index"
        ".cache/spotify"
        ".cache/sublime-text"
        ".config/yuzu"
        ".system.git"
        ".local/share/Trash"
        ".local/state/wireplumber"
        ".local/share/yuzu"
        ".mix"
        ".lyrics"
        ".steam"
      ];
    };
  };

  # Shadow can't be added to persistent
  users.users."root".passwordFile = "/var/persistent/secrets/shadow/root";
  users.users."pedrohlc".passwordFile = "/var/persistent/secrets/shadow/pedrohlc";

  # More modern stage 1 in boot
  boot.initrd.systemd.enable = true;

  # Limit resources used by nix-daemon to fix memleaks in some Python and Java derivations.
  # I always need at least 24G of RAM because of ZFS.
  systemd.services.nix-daemon.serviceConfig = {
    MemoryMax = "40G";
    MemorySwapMax = "40G";
  };

  # Printer
  services.printing = {
    enable = true;
    drivers = with pkgs; [ epson-escpr ];
  };
  # I don't want the printing service to start with system
  # and there is a ".socket" trigger that starts it when opening printing dialogs.
  systemd.services.cups.wantedBy = lib.mkForce [ ];

  # Change the allocator in hope it will save me 5 ms everyday.
  # Bug: jemalloc 5.2.4 seems to break spotify and discord, crashes firefox when exiting and freezes TabNine.
  # environment.memoryAllocator.provider = "jemalloc";

  # Necessary for playing GI
  networking.extraHosts =
    ''
      # - Required to play GI on Linux without banning.

      # Genshin logging servers (do not remove!)
      0.0.0.0 sg-public-data-api.hoyoverse.com
      0.0.0.0 log-upload-os.hoyoverse.com
      0.0.0.0 overseauspider.yuanshen.com

      # Optional Unity proxy/cdn servers
      0.0.0.0 prd-lender.cdp.internal.unity3d.com
      0.0.0.0 thind-prd-knob.data.ie.unity3d.com
      0.0.0.0 thind-gke-usc.prd.data.corp.unity3d.com
      0.0.0.0 cdp.cloud.unity3d.com
      0.0.0.0 remote-config-proxy-prd.uca.cloud.unity3d.com
    '';
}
