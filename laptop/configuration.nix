# The top lambda and it super set of parameters.
{ nix-gaming, config, lib, pkgs, ... }:

# My user-named values.
let
  # NVIDIA Offloading (ajusted to work on Wayland and XWayland).
  nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
    export __GLX_VENDOR_LIBRARY_NAME="nvidia"
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __NV_PRIME_RENDER_OFFLOAD_PROVIDER="NVIDIA-G0"
    export __VK_LAYER_NV_optimus="NVIDIA_only"
    export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/nvidia_icd.i686.json"
    export LIBVA_DRIVER_NAME="nvidia"
    exec -a "$0" "$@"
  '';

  # Preferred NVIDIA Version.
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.stable;

in
# NixOS-defined options
{
  # Full IOMMU for us
  boot.kernelParams = [ "intel_iommu=on" ];

  # Disable Intel's stream-paranoid for gaming.
  # (not working - see nixpkgs issue 139182)
  boot.kernel.sysctl."dev.i915.perf_stream_paranoid" = false;

  # Network.
  networking = {
    hostId = "0f8623ae";
    hostName = "laptop";
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
  };
  environment = {
    etc = {
      "gbm/nvidia-drm_gbm.so".source = "${nvidiaPackage}/lib/libnvidia-allocator.so";
      "egl/egl_external_platform.d".source = "/run/opengl-driver/share/egl/egl_external_platform.d/";
    };
    systemPackages = with pkgs; [
      nvidia-offload
    ];
  };

  # Intel VAAPI (NVIDIA enable its own)
  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver
    libva
  ];

  # Enable the SwayWM.
  programs.sway = {
    extraSessionCommands = ''
      # Adjust NVIDIA Optimus and use Intel by-default.
      export __GL_VRR_ALLOWED=1
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __VK_LAYER_NV_optimus="non_NVIDIA_only"
      export VK_ICD_FILENAMES="/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json"
      export LIBVA_DRIVER_NAME="iHD"

      # Gaming
      export GAMEMODERUNEXEC="nvidia-offload $GAMEMODERUNEXEC"
    '';
    extraOptions = [
      "--unsupported-gpu"
    ];
  };

  # Services/Programs configurations
  services.upower.enable = true;
  services.minidlna.friendlyName = "laptop";

  # Override packages' settings.
  nixpkgs.config.packageOverrides = pkgs: {
    steam = pkgs.steam.override {
      extraPkgs = pkgs: with pkgs; [ gamemode nvidia-offload mangohud nvidiaPackage ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

