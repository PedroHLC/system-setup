# The top lambda and it super set of parameters.
{ lib, config, pkgs, nix-gaming-edge, ... }:

# NixOS-defined options
{
  # Network.
  networking = {
    hostId = "7116ddca";
    hostName = "desktop";

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "10.100.0.2/24" "fda4:4413:3bb1::2/64" ];
      privateKeyFile = "/home/pedrohlc/Projects/com.pedrohlc/wireguard-keys/private";
      peers = [
        {
          publicKey = "kjVAAeIGsN0r3StYDQ2vnYg6MbclMrPALdm07qZtRCE=";
          allowedIPs = [
            "10.100.0.0/24"
            "fda4:4413:3bb1::/64"
            # Multicast IPs
            "224.0.0.251/32"
            "ff02::fb/128"
          ];
          endpoint = "lab.pedrohlc.com:51820";
          persistentKeepalive = 25;
        }
      ];
      postSetup = ''
        ip link set wg0 multicast on
      '';
    };
  };

  # DuckDNS
  services.ddclient = {
    enable = true;
    domains = [ "desk-pedrohlc.duckdns.org" ];
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

  # Overlay
  nixpkgs.overlays =
    let
      thisConfigsOverlay = final: prev: {
        # Add the right GE for this machine
        wine-ge = nix-gaming-edge.packages.x86_64-linux.wine-ge;
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

