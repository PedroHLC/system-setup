# The top lambda and it super set of parameters.
{ config, pkgs, nix-gaming-edge, ssot, ... }: with ssot;

# NixOS-defined options
{
  # Network.
  networking = {
    hostId = "7116ddca";
    hostName = vpn.desktop.hostname;

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "${vpn.desktop.v4}/${vpn.mask.v4}" "${vpn.desktop.v6}/${vpn.mask.v6}" ];
      privateKeyFile = "/home/pedrohlc/Projects/com.pedrohlc/wireguard-keys/private";
    };
  };

  # DuckDNS
  services.ddclient = {
    enable = true;
    domains = [ web.desktop.addr ];
    protocol = "duckdns";
    server = "www.duckdns.org";
    username = "nouser";
    passwordFile = "home/pedrohlc/Projects/com.pedrohlc/duckdns.token";
    ipv6 = false; # Does not work for duckdns protocol
  };

  # Better voltage and temperature
  boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];

  # Let's use AMD P-State
  boot.kernelParams = [
    "initcall_blacklist=acpi_cpufreq_init"
    "amd_pstate.shared_mem=1"
    # Fix "controller is down" (probably)
    "nvme_core.default_ps_max_latency_us=0" # this didn't do it
    #"pcie_aspm=off" # this didn't do it
    #"iommu=pt" # this didn't do it
  ];
  boot.kernelModules = [ "amd_pstate" ];

  # Services/Programs configurations
  services.minidlna.settings.friendly_name = "desktop";

  # OpenCL
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  # My mono-mic Focusrite
  environment.etc.pw-focusrite-mono-input = {
    source = pkgs.pw-focusrite-mono-input;
    target = "pipewire/pipewire.conf.d/focusrite-mono-input.conf";
  };

  environment.systemPackages = with pkgs; [
    vkBasalt
  ];

  # Overlay
  nixpkgs.overlays =
    let
      thisConfigsOverlay = _: _: {
        # Add the right GE for this machine
        inherit (nix-gaming-edge.packages.x86_64-linux) wine-ge;
      };
    in
    [ thisConfigsOverlay ];

  # Persistent files
  environment.persistence."/var/persistent".users.pedrohlc = {
    directories = [
      { directory = ".aws"; mode = "0700"; }
      ".cache/keybase"
      ".cache/mesa_shader_cache"
      ".cache/mozilla"
      ".cache/nix-index"
      ".cache/spotify"
      ".cache/sublime-text"
      ".local/share/containers"
      ".local/share/Trash"
      ".config/btop"
      ".config/discord"
      ".config/Element"
      { directory = ".config/Keybase"; mode = "0700"; }
      { directory = ".config/keybase"; mode = "0700"; }
      ".config/nvim"
      ".config/obs-studio"
      ".config/qBittorrent"
      ".config/spotify"
      ".config/sublime-text"
      ".config/TabNine"
      { directory = ".gnupg"; mode = "0700"; }
      { directory = ".kube"; mode = "0700"; }
      ".local/share/DBeaverData"
      ".local/share/fish"
      { directory = ".local/share/keybase"; mode = "0700"; }
      ".local/share/Steam"
      ".local/share/TelegramDesktop"
      ".local/share/Terraria"
      { directory = ".ssh"; mode = "0700"; }
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
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "22.05"; # Did you read the comment?
}

