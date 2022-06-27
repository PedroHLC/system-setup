# The top lambda and it super set of parameters.
{ config, lib, pkgs, nix-gaming, ... }:

# My user-named values.
let
  # Preferred NVIDIA Version.
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.stable;

in
# NixOS-defined options
{
  # per-device UID
  users.users.pedrohlc.uid = 1001;
  users.users.melinapn.uid = 1002;

  # Full IOMMU for us
  boot.kernelParams = [ "intel_iommu=on" ];

  # Disable Intel's stream-paranoid for gaming.
  # (not working - see nixpkgs issue 139182)
  boot.kernel.sysctl."dev.i915.perf_stream_paranoid" = false;

  # Network.
  networking = {
    hostId = "0f8623ae";
    hostName = "laptop";

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
          endpoint = "home.pedrohlc.com:51820";
          persistentKeepalive = 25;
        }
      ];
      postSetup = ''
        ip link set wg0 multicast on
      '';
    };
  };

  # NVIDIA GPU (PRIME Offloading + Wayland)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = nvidiaPackage;

    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0"; # Bus ID of the Intel GPU.
      nvidiaBusId = "PCI:1:0:0"; # Bus ID of the NVIDIA GPU.
    };

    powerManagement = {
      enable = true;
      finegrained = true;
    };
  };
  environment = {
    systemPackages = with pkgs; [
      airgeddon
      nvidia-offload
    ];
    variables = {
      "VK_ICD_FILENAMES" = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/in
tel_icd.i686.json";
    };
  };

  # Intel VAAPI (NVIDIA enable its own)
  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver
    libva
  ];

  # Services/Programs configurations
  services.upower.enable = true;
  services.minidlna.friendlyName = "laptop";

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfigsOverlay = self: super: {
        # Steam with (more) gaming-stuff
        steam = super.steam.override {
          extraPkgs = pkgs: with pkgs; [ nvidia-offload ];
        };

        # NVIDIA Offloading (ajusted to work on Wayland and XWayland).
        nvidia-offload = self.callPackage ../tools/nvidia-offload.nix { };
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

