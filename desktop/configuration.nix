# The top lambda and it super set of parameters.
{ config, lib, pkgs, nix-gaming, ... }:

# My-defined terms
let
  mesa-attrs = super: rec {
    nativeBuildInputs = super.nativeBuildInputs ++ [ pkgs.glslang ];
    mesonFlags = super.mesonFlags ++ [ "-Dvulkan-layers=device-select,overlay" ];
    postInstall = super.postInstall + ''
      mv $out/lib/libVkLayer* $drivers/lib
      layer=VkLayer_MESA_device_select
      substituteInPlace $drivers/share/vulkan/implicit_layer.d/''${layer}.json \
        --replace "lib''${layer}" "$drivers/lib/lib''${layer}"
      layer=VkLayer_MESA_overlay
      substituteInPlace $drivers/share/vulkan/explicit_layer.d/''${layer}.json \
        --replace "lib''${layer}" "$drivers/lib/lib''${layer}"
    '';
    version = "22.1.3";
    src = pkgs.fetchurl {
      url = "https://gitlab.freedesktop.org/mesa/mesa/-/archive/mesa-${version}/mesa-mesa-${version}.tar.gz";
      sha256 = "CR7we79giAock8w977zhCvZdZ6UR3sBP49Sunu9rSr0=";
    };
  };
  mesa-params = _: {
    galliumDrivers = [ "radeonsi" "zink" "virgl" "swrast" ];
    vulkanDrivers = [ "amd" "virtio-experimental" "swrast" ];
  };
in
# NixOS-defined options
{
  # per-device UID
  users.users.pedrohlc.uid = 1001;
  users.users.melinapn.uid = 1000;

  # Network.
  networking = {
    hostId = "7116ddca";
    hostName = "desktop";
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
  ];
  # Services/Programs configurations
  services.minidlna.friendlyName = "desktop";

  # OpenCL
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
  hardware.opengl.package = ((pkgs.mesa.override mesa-params).overrideAttrs mesa-attrs).drivers;
  hardware.opengl.package32 = ((pkgs.pkgsi686Linux.mesa.override mesa-params).overrideAttrs mesa-attrs).drivers;

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfigsOverlay = self: super: {
        # This desktop is affected by this bug:
        #  - https://bugzilla.kernel.org/show_bug.cgi?id=216096 in kernel 5.18
        #  - Looks like you can't have two identical NVMes right now.
        linuxPackages_zen = super.linuxPackages_zen.extend (lpSelf: lpSuper: {
          kernelPatches = (lpSuper.kernelPatches or [ ]) ++ {
            name = "nvme-pci_smi-has-bogus-namespace-ids";
            patch = self.fetchurl {
              url = "https://git.infradead.org/nvme.git/patch/c98a879312caf775c9768faed25ce1c013b4df04?hp=2cf7a77ed5f8903606f4f7833d02d67b08650442";
              sha256 = "522d3e539e77bb4bdab32b436c0f83c038536aab56d6dd04e943f27c829c06de";
            };
          };
        });
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

