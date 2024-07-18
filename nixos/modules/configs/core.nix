# The top lambda and it super set of parameters.
{ pkgs, lib, ssot, flakes, options, config, specs, ... }@inputs: with ssot;

# NixOS-defined options
{
  # Nix package-management settings.
  nix = {
    # - Enable flakes
    # - newer CLI features
    # - content-aware
    # - keep sources around for offline-building
    # - tank more of my internet connection
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations

      keep-outputs = true
      keep-derivations = true

      max-substitution-jobs = 64
      http-connections = 96
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

    # github:nix-community/* cache
    settings.substituters = [
      "https://nix-community.cachix.org/"
      "https://cache.lix.systems"
    ];
    settings.trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
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
    supportedLocales = [ "en_IE.UTF-8/UTF-8" "en_US.UTF-8/UTF-8" "pt_BR.UTF-8/UTF-8" ];
    # For apps using LANG: the closest to what I have with LC_* below
    defaultLocale = "en_IE.UTF8";
    # For apps using LC_*:
    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8"; # "pt_BR.UTF8" borks xkbcommon

      LC_NUMERIC = "pt_BR.UTF8";
      LC_TIME = "pt_BR.UTF8";
      LC_COLLATE = "pt_BR.UTF8";
      LC_MONETARY = "pt_BR.UTF8";
      LC_PAPER = "pt_BR.UTF8";
      LC_NAME = "pt_BR.UTF8";
      LC_ADDRESS = "pt_BR.UTF8";
      LC_TELEPHONE = "pt_BR.UTF8";
      LC_MEASUREMENT = "pt_BR.UTF8";
      LC_IDENTIFICATION = "pt_BR.UTF8";
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
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDe+j0odZ7Mk0p8Q9lv0HWFt62ZW6uN4wi+pp7YD8BquU8cKYlh1yk5kQxzwhEpsrIgyiOYU5CxYWkdblh+h/oLBk7seCzYF+ZZnhR5AJdbUvz8FNPbDqd81tphjntRphNArYVgdpIz0pwvYz9yvDwNXaaPfJuLTIecmIM1PaVnQOTKR6zNhwWad9bXWr4NdS2LN5rl8Yg083BKu36kcdnj8bQi7viNhbpHrwYhDUiMuysUdAd/atNJGwyFehmRckhC/Jv65eJtwR/asXTsEB9KaRAqnuThAR9bGwlMdHP/zZOhB3Bb/M+HTafOlVvBv30iJXg426EUpoMg+X0C0ZOM+wddSDRTmf2z6m/tOxguG0DNwfug1lWjZUlLeevkauBywKo1TlqQEZ9BDFgI/J34YGELJV6hUYe+rQfzcTZwQ9nLx2bcZA877Sf7sAu4ajw+p2Vcz4gypwpdT6vNfDt15w9HKJM/PCAl9Y2OxXOqogrwL1zG9P7tX5adiXp3QW8= pedrohlc@laptop"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;
  environment.shells = [ pkgs.dash ];

  # List packages.
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    aria2
    busybox_appletless
    cachix
    curl
    fastfetch
    file
    fzf
    google-authenticator
    helix
    jq
    killall
    mosh
    nix-index
    nix-top_abandoned
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

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfiguration = final: _prev: {
        nixos-clear = final.callPackage ../../../packages/scripts { scriptName = "nixos-clear"; };
        aria2c-for-wget-curl = final.callPackage ../../../packages/aria2c-for-wget-curl.nix { };
      };
    in
    [ thisConfiguration ];

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
    pinentryPackage = lib.mkForce pkgs.pinentry-curses;
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
    settings = import ../../../assets/htop-settings.nix;
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

  # Let's recover our long lost dogs (PR 122547)
  services.dbus.implementation = "broker";

  # Dashboard with data I don't really want to store, but want to check previous values sometimes
  services.datadog-agent = {
    enable = true;
    #package = pkgs.datadog-agent.override { buildGoModule = pkgs.buildGo121Module; };
    apiKeyFile = "/var/persistent/secrets/datadog.key";
    site = "datadoghq.com";
    enableLiveProcessCollection = true;
    enableTraceAgent = true;
  };

  # Help our friends worldwide
  services.snowflake-proxy.enable = true;

  # Global adjusts to home-manager
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = flakes.self.specialArgs // { nixosConfig = config; specs = inputs.specs; };

  # Set $NIX_PATH entry for nixpkgs.
  # This is for reusing flakes inputs for old commands.
  nix.nixPath = [
    "nixpkgs=${flakes.nixpkgs}"
    "chaotic=${flakes.chaotic}"
  ];

  # Always uses system's flakes instead of downloading or updating.
  nix.registry = {
    nixpkgs.flake = flakes.nixpkgs;
    chaotic.flake = flakes.chaotic;
  };

  networking.hosts = {
    # - My Network
    "${web.lab.v4}" = [ web.lab.addr web.zeta.addr ];
    "${web.lab.v6}" = [ web.lab.addr web.zeta.addr ];

    # - My VPN
    "${vpn.lab.v4}" = [ vpn.lab.addr ];
    "${vpn.lab.v6}" = [ vpn.lab.addr ];
    "${vpn.desktop.v4}" = [ vpn.desktop.addr ];
    "${vpn.desktop.v6}" = [ vpn.desktop.addr ];
    "${vpn.laptop.v4}" = [ vpn.laptop.addr ];
    "${vpn.laptop.v6}" = [ vpn.laptop.addr ];
    "${vpn.beacon.v4}" = [ vpn.beacon.addr ];
    "${vpn.beacon.v6}" = [ vpn.beacon.addr ];

    # Lock cache to GRU (Brazil)
    "151.101.250.217" = [ "cache.nixos.org" ];
  };
}
