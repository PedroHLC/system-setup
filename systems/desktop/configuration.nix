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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "21.11"; # Did you read the comment?
}

