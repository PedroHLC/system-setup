# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  slack = pkgs.slack.overrideAttrs (old: {
    installPhase = old.installPhase + ''
      rm $out/bin/slack

      makeWrapper $out/lib/slack/slack $out/bin/slack \
        --prefix XDG_DATA_DIRS : $GSETTINGS_SCHEMAS_PATH \
        --prefix PATH : ${lib.makeBinPath [pkgs.xdg-utils]} \
        --add-flags "--ozone-platform=wayland --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer"
    '';
  });

  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
    export __VK_LAYER_NV_optimus=NVIDIA_only
    unset VK_ICD_FILENAMES
    exec -a "$0" "$@"
  '';

  nowl = pkgs.writeShellScriptBin "nowl" ''
    unset CLUTTER_BACKEND
    unset ECORE_EVAS_ENGINE
    unset ELM_ENGINE
    unset SDL_VIDEODRIVER
    unset BEMENU_BACKEND
    unset GTK_USE_PORTAL
    export GDK_BACKEND='x11'
    export XDG_SESSION_TYPE='x11'
    export QT_QPA_PLATFORM='xcb'
    export MOZ_ENABLE_WAYLAND=0
    exec -a "$0" "$@"
  '';

  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.stable;

  nix-gaming = import (builtins.fetchTarball "https://github.com/fufexan/nix-gaming/archive/master.tar.gz");

  loginScript = pkgs.writeText "login-program.sh" ''
    if [[ "$(tty)" == '/dev/tty1' ]]; then
      ${pkgs.shadow}/bin/login -f pedrohlc;
    else
      ${pkgs.shadow}/bin/login;
    fi
  '';

in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Nix package management settings
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.package = pkgs.nixUnstable;

  # External binary caches
  nix = {
    trustedUsers = [ "root" "pedrohlc" ];
    binaryCaches = [ "https://nix-gaming.cachix.org" ];
    binaryCachePublicKeys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Other boot settings 
  hardware.enableRedistributableFirmware = true;
  # boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.supportedFilesystems = [ "zfs" "ntfs" ];
  boot.zfs.requestEncryptionCredentials = false;
  boot.tmpOnTmpfs = true;
  boot.kernel.sysctl = {
    "dev.i915.perf_stream_paranoid" = false;
  };


  # Network
  networking = {
    hostId = "0f8623ae";
    hostName = "laptop";

    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };

    usePredictableInterfaceNames = true;
    useDHCP = false;

    # Disable the firewall altogether.
    firewall.enable = false;
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
  };

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # GPU
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.package = nvidiaPackage;
  hardware.nvidia.prime = {
    offload.enable = true;

    # Bus ID of the Intel GPU. You can find it using lspci, either under 3D or VGA
    intelBusId = "PCI:0:2:0";

    # Bus ID of the NVIDIA GPU. You can find it using lspci, either under 3D or VGA
    nvidiaBusId = "PCI:1:0:0";
  };
  environment.etc = {
    "gbm/nvidia-drm_gbm.so".source = "${nvidiaPackage}/lib/libnvidia-allocator.so";
    "egl/egl_external_platform.d".source = "/run/opengl-driver/share/egl/egl_external_platform.d/";
  };
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver
    vaapiVdpau
    libvdpau-va-gl
    libva
  ];
  # specialisation = {
  #   external-display.configuration = {
  #     system.nixos.tags = [ "external-display" ];
  #     hardware.nvidia.prime.offload.enable = lib.mkForce false;
  #     hardware.nvidia.powerManagement.enable = lib.mkForce false;
  #   };
  # };

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
      
      export QT_QPA_PLATFORMTHEME='kde'
      export QT_PLATFORM_PLUGIN='kde'
      export QT_PLATFORMTHEME='kde'

      export __GL_VRR_ALLOWED="1"
      export __NV_PRIME_RENDER_OFFLOAD="1"
      export __VK_LAYER_NV_optimus="non_NVIDIA_only"
      export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json"
      export GAMEMODERUNEXEC="nvidia-offload mangohud env WINEFSYNC=1 PROTON_WINEDBG_DISABLE=1 DXVK_LOG_PATH=none"
    '';
    extraOptions = [
      "--unsupported-gpu"
      "--my-next-gpu-wont-be-nvidia"
    ];
  };
  xdg.portal = {
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };
  services.xserver.layout = "br";

  # Enable sound.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    media-session.enable = false;
    systemWide = false;
  };
  services.pipewire.wireplumber.enable = true;
  environment.variables = {
    AE_SINK = "ALSA";
    SDL_AUDIODRIVER = "alsa";
  };
  hardware.pulseaudio.enable = false;

  # User accounts
  users.users.pedrohlc = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "networkmanager" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Autologin
  # systemd.services."autovt@tty1".serviceConfig = autoLoginServiceConfig;
  services.getty = {
    loginProgram = "${pkgs.bash}/bin/sh";
    loginOptions = toString loginScript;
    extraArgs = [ "--skip-login" ];
  };

  # List packages installed.
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    acpi
    alacritty
    android-tools
    aria2
    avell-unofficial-control-center
    brightnessctl
    cachix
    file
    firefox
    fzf
    git
    gnome.zenity
    grim
    i3status-rust
    killall
    lm_sensors
    lxqt.pavucontrol-qt
    lxqt.pcmanfm-qt
    mako
    mosh
    mpv
    neovim
    nowl
    nix-index
    nomacs
    p7zip
    pciutils
    qbittorrent
    slack
    slurp
    spotify
    tdesktop
    tmux
    unrar
    unzip
    usbutils
    wget
    xarchiver
    xdg_utils
    xfce.tumbler
    zoom-us

    nur.repos.plabadens.sway-launcher-desktop

    dbeaver
    elmPackages.elm-format
    gnumake
    nodejs
    sublime4
    yarn

    breeze-gtk
    breeze-icons
    breeze-qt5
    oxygen-icons5
    qqc2-breeze-style
    vimix-icon-theme

    mangohud
    mesa-demos
    nvidia-offload
    vulkan-tools
    nix-gaming.packages.x86_64-linux.wine-tkg
    winetricks
  ];
  programs.dconf.enable = true;
  programs.fish.enable = true;
  programs.gamemode.enable = true;
  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.steam.enable = true;
  environment.variables.EDITOR = "nvim";
  services.jellyfin.enable = true;
  services.flatpak.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
    steam = pkgs.steam.override {
      nativeOnly = false;
      extraPkgs = pkgs: with pkgs; [ gamemode nvidia-offload mangohud ];
    };
  };

  # Fonts
  fonts.fonts = with pkgs; [
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:
  services.openssh.enable = true;

  # Virtualisation
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
    };
  };

  # GenshinImpact
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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

  # Storage optimization
  nix.autoOptimiseStore = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  system.autoUpgrade.enable = true;
}

