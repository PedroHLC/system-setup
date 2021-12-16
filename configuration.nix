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

in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Other boot settings 
  # boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.requestEncryptionCredentials = false;
  boot.tmpOnTmpfs = true;

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

  # Fans
  #hardware.fancontrol.enable = true;

  # GPU
  hardware.bumblebee.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.vulkan_beta;

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
    '';
  };
  xdg.portal.wlr.enable = true;
  services.xserver.layout = "br";

  # Enable sound.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User accounts
  users.users.pedrohlc = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "networkmanager" ];
  };
  security.sudo.wheelNeedsPassword = false;

  # Autologin
  # systemd.services."autovt@tty1".serviceConfig = autoLoginServiceConfig;
  services.getty.autologinUser = "pedrohlc";

  # List packages installed.
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    acpi
    alacritty
    aria2
    avell-unofficial-control-center
    brightnessctl
    discord-canary
    file
    firefox
    fzf
    git
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
    nomacs
    pciutils
    pulseaudio-ctl
    qbittorrent
    slack
    slurp
    spotify
    tdesktop
    tmux
    usbutils
    unzip
    vimix-icon-theme
    wget
    xarchiver
    xfce.tumbler
    zoom-us
    
    autoconf
    dbeaver
    elmPackages.elm-format
    gnumake
    sublime4
    yarn

    breeze-gtk
    breeze-icons
    breeze-qt5
    libsForQt5.plasma-integration
    libsForQt5.qtstyleplugins
    oxygen-icons5
    qqc2-breeze-style

    mesa-demos
    vulkan-tools
    mangohud
  ];
  programs.fish.enable = true;
  programs.neovim.enable = true;
  programs.neovim.viAlias = true;
  programs.neovim.vimAlias = true;
  programs.steam.enable = true;
  environment.variables.EDITOR = "nvim";

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

  # RFKILL
  system.activationScripts = {
    rfkillInit = {
      text = ''
      rfkill unblock wlan
      rfkill block bluetooth
      '';
      deps = [];
    };
  };

  # Discord fix
  pkgs.discord.override {
    nss = pkgs.nss_3_73;
  }

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

