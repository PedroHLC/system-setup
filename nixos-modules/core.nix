# The top lambda and it super set of parameters.
{ pkgs, lib, ssot, flakes, options, config, specs, ... }@inputs: with ssot;

# NixOS-defined options
{
  # Nix package-management settings.
  nix = {
    package = pkgs.nixVersions.latest;

    # - Enable flakes
    # - newer CLI features
    # - content-aware
    # - keep sources around for offline-building
    # - tank more of my internet connection
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations

      keep-outputs = true
      keep-derivations = true

      max-substitution-jobs = 48
      http-connections = 100
    '';

    # Allow my user to use nix
    settings.trusted-users = [ "root" "pedrohlc" ];

    # More caches
    settings.substituters = [ "https://nix-community.cachix.org/" "https://cache.garnix.io" ];
    settings.trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];

    # Automatically removes NixOS' older builds.
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # Use all cores for building (defaults to one in PR 199491)
    settings.max-jobs = "auto";
  };

  # Enable all the firmwares
  hardware.enableRedistributableFirmware = true;

  # I like /tmp on RAM.
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "100%";
  };

  # Kernel versions.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Remove unused features.
  services.lvm.enable = false;
  boot.swraid.enable = false;

  # Disable the firewall.
  networking.firewall.enable = false;

  # "enp2s0" instead of "eth0".
  networking.usePredictableInterfaceNames = true;

  # Default time zone.
  time.timeZone = "America/Sao_Paulo";

  # Internationalisation.
  i18n = {
    # For apps using LANG: the closest to what I have with LC_* below
    defaultLocale = "en_IE.UTF-8";
    # For apps using LC_*:
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
      LC_CTYPE = "pt_BR.UTF-8";

      LC_NUMERIC = "pt_BR.UTF-8";
      LC_TIME = "pt_BR.UTF-8";
      LC_COLLATE = "pt_BR.UTF-8";
      LC_MONETARY = "pt_BR.UTF-8";
      LC_PAPER = "pt_BR.UTF-8";
      LC_NAME = "pt_BR.UTF-8";
      LC_ADDRESS = "pt_BR.UTF-8";
      LC_TELEPHONE = "pt_BR.UTF-8";
      LC_MEASUREMENT = "pt_BR.UTF-8";
      LC_IDENTIFICATION = "pt_BR.UTF-8";
    };
  };
  console.font = "Lat2-Terminus16";

  # Earlier adoption of nixpkgs#299456
  boot.initrd.systemd.contents."/etc/kbd/consolefonts" =
    let
      cfg = config.console;
      consoleEnv = kbd: pkgs.buildEnv {
        name = "console-env";
        paths = [ kbd ] ++ cfg.packages;
        pathsToLink = [
          "/share/consolefonts"
          "/share/consoletrans"
          "/share/keymaps"
          "/share/unimaps"
        ];
      };
    in
    lib.mkIf (!cfg.earlySetup && cfg.font != null) { source = "${consoleEnv config.boot.initrd.systemd.package.kbd}/share/consolefonts"; };

  # User accounts.
  users.users.pedrohlc = {
    uid = 1001;
    isNormalUser = true;
    extraGroups = [ "wheel" "users" "audio" "video" "input" "networkmanager" "rtkit" "podman" "kvm" "adbusers" "systemd-journal" ];
    shell = pkgs.dash;
    openssh.authorizedKeys.keys = ssot.keyring.ssh;
  };
  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;
  environment.shells = [ pkgs.dash ];

  # List packages.
  environment.systemPackages = with pkgs; [
    aria2
    busybox_appletless
    curl
    evil-helix
    fastfetch
    file
    fzf
    google-authenticator
    jq
    killall
    mosh
    nix-index
    nix-top
    nmap
    p7zip
    pciutils
    ripgrep
    sshfs-fuse
    traceroute
    unrar
    unzip
    wget
    wireguard-tools
    xleak

    # my scripts
    nixos-clear
  ];

  # Configurable programs
  programs.command-not-found.enable = false;
  programs.dconf.enable = true;
  programs.fish = {
    enable = true;
    vendor = {
      config.enable = true;
      completions.enable = true;
    };
  };
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true; # So I can use GPG through SSH
    pinentryPackage =
      let
        pkg = pkgs.callPackage ../packages/scripts {
          scriptName = "pinentry";
          substitutions = {
            "@PINENTRY@" = "${pkgs.pinentry-gnome3}";
          };
        };
      in
      lib.mkForce pkg;
  };
  programs.tmux = {
    enable = true;
    clock24 = true;
  };
  programs.git = {
    enable = true;
    lfs.enable = true;
  };
  security.sudo.extraConfig = ''
    Defaults pwfeedback
  '';
  programs.htop = {
    enable = true;
    settings = import ../common/htop-settings.nix;
  };

  # Put Helix as default editor.
  environment.variables.EDITOR = "hx";

  # Enable services (automatically includes their apps' packages).
  services.timesyncd.enable = true;
  services.openssh = {
    enable = true;
    settings = {
      X11Forwarding = true;
      PermitRootLogin = "no";
      Macs = [
        # Default
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
        # Non OpenSSH compatib
        "hmac-sha2-256"
      ];
    };
  };
  programs.ssh = {
    package = pkgs.openssh_hpn;
    askPassword = lib.mkForce options.programs.ssh.askPassword.default;
  };

  # Enable google-authenticator
  security.pam.services.sshd.googleAuthenticator.enable = true;

  # Disable nixos-containers (conflicts with virtualisation.containers)
  boot.enableContainers = false;

  # Virtualisation / Containerization.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # Podman provides docker.
  };

  # dbus-broker
  services.dbus.implementation = "broker";

  # Dashboard with data I don't really want to store, but want to check previous values sometimes
  services.datadog-agent = {
    enable = true;
    apiKeyFile = "/var/persistent/secrets/datadog.key";
    site = "datadoghq.com";
    enableLiveProcessCollection = true;
    enableTraceAgent = true;
  };

  # Help our friends worldwide
  services.snowflake-proxy.enable = true;

  # Global adjusts to home-manager
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = flakes.self.specialArgs // { specs = inputs.specs; };

  # AI (use from desktop)
  environment.variables.OLLAMA_HOST = "http://${machines.desktop.vpn.v4}:${toString machines.desktop.vpn.ollamaPort}";

  # Editable hosts
  environment.etc.hosts.mode = "0644";

  # Local domains
  networking.hosts = with flakes.ullib.attrset;
    let
      essentials =
        {
          # - My Network
          "${web.lab.v4}" = [ web.lab.addr web.zeta.addr ];
          "${web.lab.v6}" = [ web.lab.addr web.zeta.addr ];
        };

      addLan =
        hostname: network: lan: union {
          "${lan.v4}" = [ "${hostname}.${network}.internal" ];
        };

      addFromSSOT =
        hostname: { vpn, lans ? { }, ... }: accu:
        {
          "${vpn.v4}" = [ vpn.addr ];
          "${vpn.v6}" = [ vpn.addr ];
        } // (foldl' (addLan hostname) lans accu);
    in
    foldl' addFromSSOT machines essentials;
}
