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
    version = "22.1.4";
    src = pkgs.fetchurl {
      url = "https://gitlab.freedesktop.org/mesa/mesa/-/archive/mesa-${version}/mesa-mesa-${version}.tar.gz";
      sha256 = "ZQrNeD23Kpks29WOwxGmNGv9wfKVfpevYsK4Pun7MjE=";
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
  services.minidlna.settings.friendlyName = "desktop";

  # OpenCL
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
  hardware.opengl.package = ((pkgs.mesa.override mesa-params).overrideAttrs mesa-attrs).drivers;
  hardware.opengl.package32 = ((pkgs.pkgsi686Linux.mesa.override mesa-params).overrideAttrs mesa-attrs).drivers;

  # Allow to cross-compile to aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfigsOverlay = self: super: {
        linuxPackages_zen = super.linuxPackages_zen.extend (lpSelf: lpSuper: {
          kernelPatches = (lpSuper.kernelPatches or [ ]) ++ [
            # This desktop is affected by this regression:
            #  - https://bugzilla.kernel.org/show_bug.cgi?id=216096 in kernel 5.18
            #  - Looks like you can't have two identical NVMes right now.
            {
              name = "nvme-pci_smi-has-bogus-namespace-ids";
              patch = self.fetchurl {
                url = "https://git.infradead.org/nvme.git/patch/c98a879312caf775c9768faed25ce1c013b4df04?hp=2cf7a77ed5f8903606f4f7833d02d67b08650442";
                sha256 = "522d3e539e77bb4bdab32b436c0f83c038536aab56d6dd04e943f27c829c06de";
              };
            }
            # This kernel version is affected by this regression:
            # - https://bugzilla.kernel.org/show_bug.cgi?id=216248
            {
              name = "acpi-fix-enabling-cppc";
              patch = self.fetchurl {
                url = "https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/patch/?id=fbd74d16890b9f5d08ea69b5282b123c894f8860";
                sha256 = "0rmyiwdcclkpxbrpj0gisvz8cqyyi8klr2mq97cig93lvmgn4kw0";
              };
            }
          ];
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

