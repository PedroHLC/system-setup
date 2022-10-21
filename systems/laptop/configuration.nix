# The top lambda and it super set of parameters.
{ config, lib, pkgs, ssot, ... }: with ssot;

# My user-named values.
let
  # Preferred NVIDIA Version.
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.latest;

in
# NixOS-defined options
{
  # Force full IOMMU
  boot.kernelParams = [ "intel_iommu=on" ];

  # Disable Intel's stream-paranoid for gaming.
  # (not working - see nixpkgs issue 139182)
  boot.kernel.sysctl."dev.i915.perf_stream_paranoid" = false;

  # Network.
  networking = {
    hostId = "0f8623ae";
    hostName = vpn.laptop.hostname;

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "${vpn.laptop.v4}/${vpn.mask.v4}" "${vpn.laptop.v6}/${vpn.mask.v6}" ];
      privateKeyFile = "/home/pedrohlc/Projects/com.pedrohlc/wireguard-keys/private";
    };
  };

  # NVIDIA GPU (PRIME Offloading + Wayland)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = nvidiaPackage;
    open = true;

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
  services.minidlna.settings.friendly_name = "laptop";

  # Useful services for power-saving
  services.auto-cpufreq.enable = true;
  services.power-profiles-daemon.enable = false; # replaced by tlp
  services.tlp.enable = true;
  services.upower.enable = true;

  # Melina may also use this machine
  users.users.melinapn = {
    uid = 1002;
    isNormalUser = true;
    extraGroups = [ "users" "audio" "video" "input" "networkmanager" ];
  };

  # Plasma for Melina
  services.xserver.desktopManager.plasma5.enable = true;

  # Override some packages' settings, sources, etc...
  nixpkgs.overlays =
    let
      thisConfigsOverlay = final: prev: {
        # Allow steam to find nvidia-offload script
        steam = prev.steam.override {
          extraPkgs = _: [ final.nvidia-offload ];
        };

        # NVIDIA Offloading (ajusted to work on Wayland and XWayland).
        nvidia-offload = final.callPackage ../../shared/pkgs/nvidia-offload.nix { };
      };
    in
    [ thisConfigsOverlay ];

  # Creates a second boot entry without nvidia-open
  specialisation.nvidia-proprietary.configuration = {
    system.nixos.tags = [ "nvidia-proprietary" ];
    hardware.nvidia.open = lib.mkForce false;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "21.11"; # Did you read the comment?
}

