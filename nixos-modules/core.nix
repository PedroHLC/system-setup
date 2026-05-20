# The top lambda and it super set of parameters.
{ pkgs, lib, ssot, flakes, options, config, specs, ... }@inputs: with ssot;

# NixOS-defined options
{
  # Nix package-management settings.
  nix = {
    # I actually wanted nixVersions.nix_2_23, but that's not a thing.
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

    # Automatically removes NixOS' older builds.
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    # Use all cores for building (defaults to one in PR 199491)
    settings.max-jobs = "auto";

    # More caches
    settings.substituters = flakes.nyx-loner.nixConfig.extra-substituters;
    settings.trusted-public-keys = flakes.nyx-loner.nixConfig.extra-trusted-public-keys;
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
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+XO1v27sZQO2yV8q2AfYS/I/l9pHK33a4IjjrNDhV+YBlLbR2iB+L5iNu7x8tKDXYscynxJPHB3vWwerZXOh35SXdh5TE9Lez02Ck466fJnTjNxX63FvppXmMx8HaVYzymojDi+xTXMO4DxNFFrJTUIagWs8WNxEbYdGAaIKRQHB0ZWMSsyaY2XkR9RkV3I9QwKNrTnkC5h8bVn63LvTuORlTvY/Iu202M2toxOKWDQ5qdSrLfNaPl7kxWUVTCpyZ8Hza75sH3SB3/m8Queeq+E48nqjL7s9ZyO1TGf6ojaf2EGfx6H8jFwycXUD2QNLvsZcWmamyLPNbHY63jjOb pedrohlc@desktop"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/vOidQLdDQ+vCet6trM5RRZJ6xujf4YJOve4vAdzBCUk30JQ3g3Kbkkdq3AWmvwRpUEkMxMiIGweiFXphvfIJvyHdSXaFoury8Va1n6I5bUS7ntaQI5R2SKBh2WHW1q/tzP5W7UxS4DwYg3kEXZp0V7sqTbw+4t8ctcS51Wam6LuUidqikukYQwKoz9DI9q0B3+U6qTl21jXwpZtqpvcTeC3ElqrkhgN4h4hNgWyjHGmfiB9NpGwPhwyfreRRiyVPXgGU9M9vI7D95ga+6eDS04aQph/MrEWgAh8jDvPzJW4PIQumhTtJdw/8v+vPqPM6+aAlwDoEKnZg1INsBb4R pedrohlc@poco-x3"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDe+j0odZ7Mk0p8Q9lv0HWFt62ZW6uN4wi+pp7YD8BquU8cKYlh1yk5kQxzwhEpsrIgyiOYU5CxYWkdblh+h/oLBk7seCzYF+ZZnhR5AJdbUvz8FNPbDqd81tphjntRphNArYVgdpIz0pwvYz9yvDwNXaaPfJuLTIecmIM1PaVnQOTKR6zNhwWad9bXWr4NdS2LN5rl8Yg083BKu36kcdnj8bQi7viNhbpHrwYhDUiMuysUdAd/atNJGwyFehmRckhC/Jv65eJtwR/asXTsEB9KaRAqnuThAR9bGwlMdHP/zZOhB3Bb/M+HTafOlVvBv30iJXg426EUpoMg+X0C0ZOM+wddSDRTmf2z6m/tOxguG0DNwfug1lWjZUlLeevkauBywKo1TlqQEZ9BDFgI/J34YGELJV6hUYe+rQfzcTZwQ9nLx2bcZA877Sf7sAu4ajw+p2Vcz4gypwpdT6vNfDt15w9HKJM/PCAl9Y2OxXOqogrwL1zG9P7tX5adiXp3QW8= pedrohlc@xbox"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDyrnJw0jEN3OnAHPzMW1eUwNRk03Ba0bU1sLpRh51f+4M1LwLAraQtkg1bKe01cQGWWvNe1NUW0jGFywuvV2jwxcXb5bWSun9FpXfd0B9EMC/+uOCMBlEKflSkbzIGnLNbxWsVgAzzas+RbgyiFIlZ58qpUlhw2Iqp6eUGdH2ZtEm6WwU3PYB21UmEvthiDwfHImiWllpevfCmARMMndZy6/A6ygUrUQ4CBinya5K9SgxSDU20wo8ae4pQERtFIpYoW4HZ3iug/k+RW00Z9ofNN5YAFQYl+kS3jFQVH7Yz2PBbjbhF0qrKWwxg7pSn5gu+YRbZpZhZcqPzkuoZuTTq3/agNcH7nSOGtYFU9Mqx6BU/hRneUWUyLBO2qduHXBHATGvColuO9rMdu6EeVFpeSmVFXnTHkwisaBomQLwQn81aWKsWBPPJ9IbZur4t8SVBWxRunpz05cmgW9xCirzQbF68Uxw6qxG787CDF0aS8r0f/tj5o1Ef2DJhr4w+QV8= pedrohlc@foreign"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGZnStto8hBFlifmfssDdkz0MFEQe9txsX1A/xQNLmQy pedrohc@astrophone"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;
  environment.shells = [ pkgs.dash ];

  # List packages.
  environment.systemPackages = with pkgs; [
    aria2
    busybox_appletless
    cachix
    curl
    fastfetch
    file
    fzf
    google-authenticator
    evil-helix
    jq
    killall
    mosh
    nix-index
    # nix-top
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
  networking.hosts = {
    # - My Network
    "${web.lab.v4}" = [ web.lab.addr web.zeta.addr ];
    "${web.lab.v6}" = [ web.lab.addr web.zeta.addr ];

    # - My VPN
    "${machines.lab.vpn.v4}" = [ machines.lab.vpn.addr ];
    "${machines.lab.vpn.v6}" = [ machines.lab.vpn.addr ];
    "${machines.desktop.vpn.v4}" = [ machines.desktop.vpn.addr ];
    "${machines.desktop.vpn.v6}" = [ machines.desktop.vpn.addr ];
    "${machines.xbox.vpn.v4}" = [ machines.xbox.vpn.addr ];
    "${machines.xbox.vpn.v6}" = [ machines.xbox.vpn.addr ];
    "${machines.foreign.vpn.v4}" = [ machines.foreign.vpn.addr ];
    "${machines.foreign.vpn.v6}" = [ machines.foreign.vpn.addr ];
    "${machines.beacon.vpn.v4}" = [ machines.beacon.vpn.addr ];
    "${machines.beacon.vpn.v6}" = [ machines.beacon.vpn.addr ];
  };
}
