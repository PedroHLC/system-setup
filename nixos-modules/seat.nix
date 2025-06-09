# The top lambda and it super set of parameters.
{ config, lib, pkgs, ssot, ... }: with ssot;

# NixOS-defined options
{
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

  # My preferred kernel
  boot.kernelPackages = lib.mkOverride 99 pkgs.linuxPackages_cachyos;

  # Filesytems settings.
  boot.supportedFilesystems = [ "zfs" "vfat" "ntfs3" ];
  boot.zfs.requestEncryptionCredentials = false;
  boot.zfs.package = lib.mkOverride 99 pkgs.zfs_cachyos;

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

    # https://wiki.cachyos.org/configuration/general_system_tweaks/#disabling-split-lock-mitigate
    "kernel.split_lock_mitigate=0"

    # Plymouth stuff
    "quiet"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];
  boot.kernel.sysctl = {
    "kernel.sysrq" = 1; # Enable ALL SysRq shortcuts
    "vm.max_map_count" = 2147483642; # helps with Wine ESYNC/FSYNC
  };

  # I prefer to trim using ZFS' "autotrim"
  services.zfs.trim.enable = false;

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
    nssmdns4 = true;
    nssmdns6 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
      userServices = true;
    };
  };

  # Bluetooth.
  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluez5-experimental;
    settings.General.Experimental = true;
  };
  services.blueman.enable = true;

  # GPU
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # XDG-Portal (for dialogs & screensharing).
  xdg.portal = {
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      kdePackages.xdg-desktop-portal-kde
    ];
    config.common.default = "*";
  };

  # XWayland keyboard layout.
  services.xserver.xkb.layout = "br";
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
  services.pulseaudio.enable = false;
  security.rtkit.enable = true; # OpenAL likes it, but my pipewire is not configure to rt.
  environment.variables.AE_SINK = "ALSA"; # For Kodi, better latency/volume under pw.
  environment.variables.SDL_AUDIODRIVER = "pipewire";
  environment.variables.ALSOFT_DRIVERS = "pipewire";

  # Workaround for nixpkgs#238025.
  environment.variables.TZ = ":/etc/localtime";

  # Autologin.
  services.getty = {
    loginProgram = "${pkgs.bash}/bin/sh";
    loginOptions =
      let
        programScript = pkgs.callPackage ../packages/login-program.nix { };
      in
      toString programScript;
    extraArgs = [ "--skip-login" ];
  };

  # List packages.
  environment.systemPackages = with pkgs; [
    # Common dependencies
    kdePackages.kio # Fixes "Unknown protocol 'file'."
    lxmenu-data # For lxqt apps' "Open with" dialogs
    pamixer # For avizo
    qt6.qtwayland # For Qt6+Wayland apps

    # Desktop apps
    acpi
    adbfs-rootless
    alacritty_git
    audacious
    bat
    bind.dnsutils # "dig"
    bluez-tools
    brightnessctl
    btop
    ethtool
    ffmpegthumbnailer
    firefox_nightly
    google-chrome
    helvum
    keybase-gui
    libinput
    libinput-gestures
    libnotify
    kdePackages.kwalletmanager
    libva-utils
    lm_sensors
    lxqt.lxqt-sudo
    pwvucontrol_git
    lxqt.pcmanfm-qt
    mpv-vapoursynth
    nomacs
    obs-studio-wrapped
    osdlyrics
    qbittorrent
    slack
    tidal-hifi
    usbutils
    waypipe
    wl-mirror
    wl-clipboard-rs
    xarchiver
    xdg-utils

    # My scripts
    nowl
    wayland-env
    ssh-to-nix

    # Development apps
    bytecode-viewer_git
    dbeaver-bin
    gcc
    gdb # more precious then gcc
    gnumake
    heroku
    inotify-tools # watching files
    logstalgia # Chaotic
    python3Minimal
    zed-editor_git

    # Office-stuff
    inkscape
    gimp
    wpsoffice

    # Social
    telegram-desktop_git
    tuba
    vesktop

    # Gaming tools
    bigsteam
    mangoapprun
    mangohud_git
    mesa-demos
    vulkan-caps-viewer
    vulkanPackages_latest.vulkan-tools
    winetricks
    gamescope-wsi_git
    gamescope-wsi32_git

    # Gaming
    devilutionx
    duckstation
    openmohaa_git
    openrct2
    space-cadet-pinball
    torzu_git
    vcmi
  ];

  # The base GUI toolkit in my setup.
  qt = {
    enable = true;
    platformTheme = "kde";
  };

  # Special apps (requires more than their package to work).
  programs.adb.enable = true;
  programs.gamemode.enable = true;

  # Fix swaylock (nixpkgs issue 158025)
  security.pam.services.swaylock = { };
  security.pam.services.swaylock-plugin = { };

  # Other preferences
  environment.variables.GAMEMODERUNEXEC = "WINEFSYNC=1 PROTON_WINEDBG_DISABLE=1 DXVK_LOG_PATH=none DXVK_HUD=compiler WINEDEBUG=-all DXVK_LOG_LEVEL=none";
  environment.variables.WINEPREFIX = "/dev/null";

  # Enable services (automatically includes their apps' packages).
  services.fwupd.enable = true;
  services.gvfs.enable = true;
  programs.kdeconnect.enable = true;
  services.keybase.enable = true;
  services.kbfs.enable = true;
  services.tumbler.enable = true;
  services.dbus = {
    enable = true;
    packages = with pkgs; [ osdlyrics kdePackages.kwallet ];
  };

  # STUPID ZOOM IS STUPID
  systemd.tmpfiles.rules = [
    "L+ /usr/libexec/xdg-desktop-portal - - - - ${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal"
  ];

  # Fonts.
  fonts = {
    enableDefaultPackages = true; # Those fonts you expect every distro to have.
    packages = with pkgs; [
      borg-sans-mono
      cantarell-fonts
      fira
      fira-code
      fira-code-symbols
      font-awesome_4
      font-awesome_5
      nerd-fonts.droid-sans-mono
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
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

  # Steam with steam-session
  programs.steam = {
    enable = true;
    gamescopeSession = {
      enable = true; # Gamescope session is better for AAA gaming.
      args = [ "--immediate-flips" "--" "bigsteam" ];
    };
  };

  # The default's CLI gamescope.
  programs.gamescope = {
    enable = true;
    capSysNice = true;
    env = lib.mkForce {
      # I set DXVK_HDR in the alternative-sessions script.
      ENABLE_GAMESCOPE_WSI = "1";
    };
    package = pkgs.gamescope_git;
  };

  # Gamescope without wrapper, but with right capabilities
  security.wrappers.valve-gamescope = {
    owner = "root";
    group = "root";
    source = "${pkgs.gamescope_git}/bin/gamescope";
    capabilities = "cap_sys_nice+pie";
  };
  environment.variables.GAMESCOPE_NOWRAP = "${config.security.wrapperDir}/valve-gamescope";

  # Gamescope untouched (no wrapper, no capabilities) in a fixed-path place
  fileSystems."/opt/gamescope" = {
    device = pkgs.gamescope_git.outPath;
    fsType = "none";
    options = [ "bind" "ro" "x-gvfs-hide" ];
  };

  # For out-of-box gaming with Heroic Game Launcher
  services.flatpak.enable = true;

  # Smooth-criminal bleeding-edge Mesa3D
  chaotic.mesa-git = {
    enable = true;
    fallbackSpecialisation = false;
  };

  # Allow to cross-compile to aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Virtualisation / Containerization.
  virtualisation.containers.storage.settings = {
    storage = {
      driver = lib.mkForce "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };

    storage.options.zfs = {
      fsname = "zroot/containers";
      mountopt = "nodev";
    };
  };

  # An alternative AP with only WiFi 6
  # Adapted from https://gist.github.com/iffa/290b1b83b17f51355c63a97df7c1cc60
  services.hostapd = {
    enable = true;
    package = pkgs.hostapd_nolar;
    radios.wlan0 = {
      channel = 149;
      networks.wlan0 = {
        apIsolate = true;
        ssid = "uaifai";
        authentication = {
          wpaPasswordFile = "/var/persistent/secrets/hostapd.psw";
          mode = "wpa2-sha256";
        };
        settings = {
          beacon_int = 100;
          bridge = "br0";
          country_code = "FI";
          dtim_period = 2;
          fragm_threshold = -1;
          ieee80211ax = 1;
          ieee80211d = 1;
          ieee80211h = 1;
          ieee80211w = 2;
          local_pwr_constraint = 3;
          max_num_sta = 255;
          rsn_pairwise = "CCMP";
          rsn_preauth = 1;
          rts_threshold = -1;
          spectrum_mgmt_required = 1;
          wmm_enabled = 1;
        };
      };
      # I manually manage 802.11 features above
      band = "6g";
      wifi7.enable = false;
      wifi6.enable = false;
      wifi5.enable = false;
      wifi4.enable = false;
    };
  };
  systemd.services.hostapd.wantedBy = lib.mkForce [ ]; # don't start automatically

  # Pull all plasma things, don't had time to separate stuff to extract its LookAndFeel
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    plasma-browser-integration
    konsole
    # (lib.getBin qttools)
    ark
    elisa
    gwenview
    okular
    kate
    khelpcenter
    dolphin
    baloo-widgets
    dolphin-plugins
    spectacle
    ffmpegthumbs
    krdp
    xwaylandvideobridge
  ];

  # For development, but disabled to start service on-demand
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql; # always the latest
    settings = {
      # log_statement = "all";
      # logging_collector = true;
      log_destination = lib.mkForce "syslog";
    };
  };
  systemd.services.postgresql.wantedBy = lib.mkForce [ ]; # don't start with system

  # Have my portal settings created through users' files
  systemd.user.services.xdg-desktop-portal-wlr.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr"
  ];

  # Bigger internet
  services.kubo = {
    enable = true;
    startWhenNeeded = true;
  };
  users.users.pedrohlc.extraGroups = [ config.services.kubo.group ];

  # Creates a second boot entry with LTS kernel, stable ZFS, stable Mesa3D.
  specialisation.safe.configuration = {
    system.nixos.tags = [ "lts" "zfs-stable" ];
    boot.kernelPackages = lib.mkOverride 98 pkgs.linuxPackages;
    boot.zfs.package = lib.mkForce pkgs.zfs;
    chaotic.mesa-git.enable = lib.mkForce false;
    chaotic.hdr.enable = lib.mkForce false;
  };

  # Change my MOUSE4 and MOUSE5 behavior (found it with "evtest")
  # - on both Dongle and Bluetooth mode
  services.udev.extraHwdb = ''
    evdev:name:Corsair CORSAIR KATAR PRO Wireless Gaming Dongle:*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_90005=key_pageup
      KEYBOARD_KEY_90004=key_pagedown
    evdev:name:KATAR PRO Wireless Mouse:*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_90005=key_pageup
      KEYBOARD_KEY_90004=key_pagedown
      KEYBOARD_KEY_90004=key_pagedown
    evdev:name:Logitech USB Receiver Mouse:*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_90005=key_pageup
      KEYBOARD_KEY_90004=key_pagedown
  '';

  # Udev rules
  # Mostly stolen from https://wiki.cachyos.org/features/cachyos_settings/#udev-rules
  services.udev.extraRules = ''
    # NTSync from user-space
    KERNEL=="ntsync", MODE="0644"

    # HDD scheduler
    ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", \
        ATTR{queue/scheduler}="bfq"

    # SSD scheduler
    ACTION=="add|change", KERNEL=="sd[a-z]*|mmcblk[0-9]*", ATTR{queue/rotational}=="0", \
        ATTR{queue/scheduler}="mq-deadline"

    # NVMe SSD scheduler
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/rotational}=="0", \
        ATTR{queue/scheduler}="none"
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
      "/var/lib/flatpak" # todo: move to residues
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
        { directory = ".android"; mode = "0700"; } # adb keys
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
        ".config/discord" # todo: move to residues
        ".config/Element"
        ".config/github-copilot"
        { directory = ".config/Keybase"; mode = "0700"; }
        { directory = ".config/keybase"; mode = "0700"; }
        ".config/lan-mouse"
        ".config/nvim"
        { directory = ".config/kdeconnect"; mode = "0700"; }
        { directory = ".config/kwalletrc"; mode = "0700"; }
        ".config/obs-studio"
        ".config/osdlyrics"
        ".config/qBittorrent"
        ".config/StardewValley"
        ".config/sunshine"
        ".config/TabNine"
        ".config/zed"
        { directory = ".gnupg"; mode = "0700"; }
        { directory = ".kube"; mode = "0700"; }
        ".local/share/DBeaverData"
        ".local/share/fish"
        ".local/share/gamescope"
        ".local/share/chat.fluffy.fluffychat"
        ".local/share/heroku"
        { directory = ".local/share/keybase"; mode = "0700"; }
        { directory = ".local/share/kwalletd"; mode = "0700"; }
        ".local/share/qBittorrent"
        ".local/share/Steam" # todo: move to residues, but keep saves somehow
        ".local/share/TelegramDesktop"
        ".local/share/Terraria"
        ".openmohaa"
        { directory = ".secrets"; mode = "0700"; }
        { directory = ".ssh"; mode = "0700"; }
        ".var/app" # todo: move to residues
        "Documents"
        "Downloads"
        "Pictures"
        "Projects"
        "Videos"
      ];
      files = [
        ".Bytecode-Viewer/recentfiles.json"
        ".Bytecode-Viewer/settings.bcv"
        { file = ".cache/keybasekeybase.app.serverConfig"; parentDirectory.mode = "0700"; }
        { file = ".google_authenticator"; parentDirectory.mode = "0700"; }
        { file = ".netrc"; parentDirectory.mode = "0700"; }
      ];
    };
  };

  # Not important but persistent files
  environment.persistence."/var/residues" = {
    hideMounts = true;
    directories = [
      "/var/cache"
      "/var/lib/AccountsService"
      "/var/lib/ipfs"
      "/var/lib/nixos"
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
        ".cache/zed"
        ".config/google-chrome"
        ".config/tidal-hifi"
        ".config/vesktop"
        ".config/Slack"
        ".config/Unknown Organization"
        ".config/yuzu"
        { directory = ".gdfuse"; mode = "0700"; }
        ".i2pd"
        ".kodi"
        ".local/share/atuin"
        ".local/share/baloo"
        ".local/share/duckstation" # todo: backup saves somehow
        ".local/share/Trash"
        ".local/state/wireplumber"
        ".local/share/yuzu" # todo: backup saves somehow
        ".local/share/zed"
        ".mix"
        ".nyx"
        ".lyrics"
        ".steam"
        ".supermaven"
        ".system.git"
        ".zoom"
      ];
      files = [
        { file = ".config/zoom.conf"; parentDirectory.mode = "0700"; }
        { file = ".config/zoomus.conf"; parentDirectory.mode = "0700"; }
      ];
    };
  };

  # Shadow can't be added to persistent
  users.users."root".hashedPasswordFile = "/var/persistent/secrets/shadow/root";
  users.users."pedrohlc".hashedPasswordFile = "/var/persistent/secrets/shadow/pedrohlc";

  # More modern stage 1 in boot
  boot.initrd.systemd.enable = true;

  # Pedro Pedro Pedro
  boot.consoleLogLevel = lib.mkForce 3;
  boot.plymouth = {
    enable = true;
    theme = "pedro-raccoon";
    themePackages = [(
      pkgs.fetchFromGitHub {
        owner = "FilaCo";
        repo = "plymouth-theme-pedro-raccoon";
        rev = "f7fde1da0dde1ce861dff5617c79de6afbde29cb";
        hash = "sha256-AT5fiF0hDeb7xqk1Ni04kqE6R88ENQ2k7rlHW3cr+PU=";
        sparseCheckout = [ "pedro-raccoon" ];
        postFetch = ''
          mkdir -p $out/share/plymouth/themes
          mv $out/pedro-raccoon $out/share/plymouth/themes/
          substituteInPlace $out/share/plymouth/themes/pedro-raccoon/pedro-raccoon.plymouth \
            --replace-fail /usr/share/ /etc/
        '';
      }
    )];
  };

  # Service for unblocking some regional restrictions
  services.tor = {
    enable = true;
    client.enable = true;
  };

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

  # Let's avoid sending sensitive data to cloud
  services.datadog-agent.enable = lib.mkForce false;
}
