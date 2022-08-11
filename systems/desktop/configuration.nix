# The top lambda and it super set of parameters.
{ config, lib, pkgs, nix-gaming, ... }:

# My-defined terms
let
  # Functions to construct my custom build of mesa
  mesa-attrs = prev: rec {
    nativeBuildInputs = prev.nativeBuildInputs ++ [ pkgs.glslang ];
    mesonFlags = prev.mesonFlags ++ [ "-Dvulkan-layers=device-select,overlay" ];
    postInstall = prev.postInstall + ''
      mv $out/lib/libVkLayer* $drivers/lib
      layer=VkLayer_MESA_device_select
      substituteInPlace $drivers/share/vulkan/implicit_layer.d/''${layer}.json \
        --replace "lib''${layer}" "$drivers/lib/lib''${layer}"
      layer=VkLayer_MESA_overlay
      substituteInPlace $drivers/share/vulkan/explicit_layer.d/''${layer}.json \
        --replace "lib''${layer}" "$drivers/lib/lib''${layer}"
    '';
    version = "22.1.6";
    src = pkgs.fetchurl {
      url = "https://gitlab.freedesktop.org/mesa/mesa/-/archive/mesa-${version}/mesa-mesa-${version}.tar.gz";
      hash = "sha256-z9WR28fgH5/g7QJz4/VehxP5/+x4/STgWnZLQyZQPcc=";
    };
  };
  mesa-params = _: {
    galliumDrivers = [ "radeonsi" "zink" "virgl" "swrast" ];
    vulkanDrivers = [ "amd" "virtio-experimental" "swrast" ];
  };
in
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

  # Let's use AMD P-State (Needs patching in 5.18.12)
  #boot.kernelParams = [
  #  "initcall_blacklist=acpi_cpufreq_init"
  #];

  # Services/Programs configurations
  services.minidlna.settings.friendly_name = "desktop";

  # OpenCL
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
  hardware.opengl.package = pkgs.mesa-bleeding;
  hardware.opengl.package32 = pkgs.lib32-mesa-bleeding;

  # Allow to cross-compile to aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfigsOverlay = final: prev: {
        # Latest mesa with more specific drivers
        mesa-bleeding = ((prev.mesa.override mesa-params).overrideAttrs mesa-attrs).drivers;
        lib32-mesa-bleeding = ((prev.pkgsi686Linux.mesa.override mesa-params).overrideAttrs mesa-attrs).drivers;
      };
    in
    [ thisConfigsOverlay ];

  # Keep some devivations's sources around so we don't have to re-download them between updates.
  lucasew.gc-hold = with pkgs; [ mesa-bleeding lib32-mesa-bleeding ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "21.11"; # Did you read the comment?
}

