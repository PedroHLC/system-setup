# The top lambda and it super set of parameters.
{ pkgs, nixpkgs, ssot, pedrochrome-css, ... }: with ssot;

# NixOS-defined options
{
  # Nix package-management settings.
  nix = {
    # Enable flakes, newer CLI features, CA, and keep sources around for offline-building
    extraOptions = ''
      experimental-features = nix-command flakes ca-derivations

      keep-outputs = true
      keep-derivations = true
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
  };

  # Enable all the firmwares
  hardware.enableRedistributableFirmware = true;

  # I like /tmp on RAM.
  boot.tmpOnTmpfs = true;
  boot.tmpOnTmpfsSize = "100%";

  # Kernel versions (I prefer Liquorix).
  boot.kernelPackages = pkgs.linuxPackages_lqx;

  # Disable the firewall.
  networking.firewall.enable = false;

  # "enp2s0" instead of "eth0".
  networking.usePredictableInterfaceNames = true;

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
  console.font = "Lat2-Terminus16";

  # User accounts.
  users.users.pedrohlc = {
    uid = 1001;
    isNormalUser = true;
    extraGroups = [ "wheel" "users" "audio" "video" "input" "networkmanager" "rtkit" "podman" "minidlna" "kvm" "adbusers" ];
    shell = pkgs.dash;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+XO1v27sZQO2yV8q2AfYS/I/l9pHK33a4IjjrNDhV+YBlLbR2iB+L5iNu7x8tKDXYscynxJPHB3vWwerZXOh35SXdh5TE9Lez02Ck466fJnTjNxX63FvppXmMx8HaVYzymojDi+xTXMO4DxNFFrJTUIagWs8WNxEbYdGAaIKRQHB0ZWMSsyaY2XkR9RkV3I9QwKNrTnkC5h8bVn63LvTuORlTvY/Iu202M2toxOKWDQ5qdSrLfNaPl7kxWUVTCpyZ8Hza75sH3SB3/m8Queeq+E48nqjL7s9ZyO1TGf6ojaf2EGfx6H8jFwycXUD2QNLvsZcWmamyLPNbHY63jjOb pedrohlc@desktop"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/vOidQLdDQ+vCet6trM5RRZJ6xujf4YJOve4vAdzBCUk30JQ3g3Kbkkdq3AWmvwRpUEkMxMiIGweiFXphvfIJvyHdSXaFoury8Va1n6I5bUS7ntaQI5R2SKBh2WHW1q/tzP5W7UxS4DwYg3kEXZp0V7sqTbw+4t8ctcS51Wam6LuUidqikukYQwKoz9DI9q0B3+U6qTl21jXwpZtqpvcTeC3ElqrkhgN4h4hNgWyjHGmfiB9NpGwPhwyfreRRiyVPXgGU9M9vI7D95ga+6eDS04aQph/MrEWgAh8jDvPzJW4PIQumhTtJdw/8v+vPqPM6+aAlwDoEKnZg1INsBb4R pedrohlc@poco-x3"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDe+j0odZ7Mk0p8Q9lv0HWFt62ZW6uN4wi+pp7YD8BquU8cKYlh1yk5kQxzwhEpsrIgyiOYU5CxYWkdblh+h/oLBk7seCzYF+ZZnhR5AJdbUvz8FNPbDqd81tphjntRphNArYVgdpIz0pwvYz9yvDwNXaaPfJuLTIecmIM1PaVnQOTKR6zNhwWad9bXWr4NdS2LN5rl8Yg083BKu36kcdnj8bQi7viNhbpHrwYhDUiMuysUdAd/atNJGwyFehmRckhC/Jv65eJtwR/asXTsEB9KaRAqnuThAR9bGwlMdHP/zZOhB3Bb/M+HTafOlVvBv30iJXg426EUpoMg+X0C0ZOM+wddSDRTmf2z6m/tOxguG0DNwfug1lWjZUlLeevkauBywKo1TlqQEZ9BDFgI/J34YGELJV6hUYe+rQfzcTZwQ9nLx2bcZA877Sf7sAu4ajw+p2Vcz4gypwpdT6vNfDt15w9HKJM/PCAl9Y2OxXOqogrwL1zG9P7tX5adiXp3QW8= pedrohlc@laptop"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;

  # List packages.
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    aria2
    btop
    busyboxWithoutAppletSymlinks
    file
    fzf
    git
    google-authenticator
    jq
    killall
    mosh
    neofetch
    nix-index
    nmap
    p7zip
    pciutils
    sshfs-fuse
    traceroute
    unrar
    unzip
    uutils-coreutils
    wget
    wireguard-tools
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
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true; # So I can use GPG through SSH
    pinentryFlavor = "tty";
  };
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

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfigsOverlay = _: prev: {
        # Allow uutils to replace GNU coreutils.
        uutils-coreutils = prev.uutils-coreutils.override { prefix = ""; };

        # Busybox without applets
        busyboxWithoutAppletSymlinks = prev.busybox.override {
          enableAppletSymlinks = false;
        };
      };
    in
    [ thisConfigsOverlay ];

  # Enable services (automatically includes their apps' packages).
  services.ntp.enable = true;
  services.openssh = {
    # TODO: Use openssh_hpn
    enable = true;
    forwardX11 = true;
    permitRootLogin = "no";
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

  # We are anxiously waiting for PR 122547
  #services.dbus-broker.enable = true;

  # Global adjusts to home-manager
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit ssot pedrochrome-css; };

  # Set $NIX_PATH entry for nixpkgs.
  # This is for reusing flakes inputs for old commands.
  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];

  # Always uses system's flakes instead of downloading or updating.
  nix.registry.nixpkgs.flake = nixpkgs;

  networking.extraHosts =
    ''
      # - My Network

      ${web.lab.v4} ${web.lab.addr}
      ${web.lab.v6} ${web.lab.addr}
      ${web.zeta.v4} ${web.zeta.addr}
      ${web.zeta.v6} ${web.zeta.addr}

      # - My VPN

      ${vpn.lab.v4} ${vpn.lab.addr}
      ${vpn.lab.v6} ${vpn.lab.addr}
      ${vpn.desktop.v4} ${vpn.desktop.addr}
      ${vpn.desktop.v6} ${vpn.desktop.addr}
      ${vpn.laptop.v4} ${vpn.laptop.addr}
      ${vpn.laptop.v6} ${vpn.laptop.addr}
    '';
}
