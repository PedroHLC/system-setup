# The top lambda and it super set of parameters.
{ config, lib, pkgs, ssot, ... }: with ssot;

# NixOS-defined options
{
  boot.kernelParams = [
    # Force full IOMMU
    "intel_iommu=on"

    # enable GSP
    "nouveau.config=NvGspRm=1"

    # to see GSP loading on dmesg
    "nouveau.debug=\"GSP=debug\""

    # https://wiki.cachyos.org/configuration/general_system_tweaks/#enable-rcu-lazy
    "rcutree.enable_rcu_lazy=1"
  ];

  # More stuff have GSP
  boot.initrd.kernelModules = [ "nouveau" ];

  # Disable Intel's stream-paranoid for gaming.
  # (not working - see nixpkgs issue 139182)
  boot.kernel.sysctl."dev.i915.perf_stream_paranoid" = false;

  # Video Acceleration
  chaotic.mesa-git.extraPackages = with pkgs; [ intel-media-driver ];

  # Network.
  networking = {
    hostId = "0f8623ae";
    hostName = vpn.laptop.hostname;

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "${vpn.laptop.v4}/${vpn.mask.v4}" "${vpn.laptop.v6}/${vpn.mask.v6}" ];
      privateKeyFile = "/var/persistent/secrets/wireguard-keys/private";
    };

    wireguard.interfaces.wg1.privateKeyFile = "/var/persistent/secrets/wgcf-teams/private";
  };

  # System-wide changes
  environment = {
    systemPackages = with pkgs; [
      airgeddon
      (cfwarp-add.override { substitutions = { "eno1" = "wlan0"; }; })
      nvidia-offload
    ];
    # Prefer intel unless told so
    variables = {
      "WLR_DRM_DEVICES" = "/dev/dri/card1";
      "VK_DRIVER_FILES" = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json";
      "LIBVA_DRIVER_NAME" = "iHD";
    };
    # Helps me debugging kernel modules
    etc.haunted_place.source =
      let
        kernel-name = config.boot.kernelPackages.kernel.name or "kernel";
      in
      pkgs.makeModulesClosure {
        rootModules = config.boot.initrd.availableKernelModules ++ config.boot.initrd.kernelModules;
        kernel = config.system.modulesTree.override { name = kernel-name + "-modules"; };
        firmware = config.hardware.firmware;
        allowMissing = false;
      };
  };

  # Intel VAAPI (NVIDIA enable its own)
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
  ];

  # Useful services for power-saving
  services.auto-cpufreq.enable = true;
  services.power-profiles-daemon.enable = false; # replaced by tlp
  services.tlp.enable = true;
  services.upower.enable = true;

  # Limit resources used by nix-daemon.
  systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "2-15";

  # Melina may also use this machine
  users.users.melinapn = {
    uid = 1002;
    isNormalUser = true;
    extraGroups = [ "users" ];
  };

  # Autologin (with Melina).
  services.getty.loginOptions =
    let
      programScript = pkgs.callPackage ../../packages/login-program.nix {
        loginsPerTTY = {
          "/dev/tty1" = "pedrohlc";
          "/dev/tty2" = "melinapn";
        };
      };
    in
    lib.mkForce (toString programScript);

  # Persistent files
  environment.persistence."/var/persistent".directories = [
    { directory = "/var/lib/colord"; user = "colord"; group = "colord"; mode = "u=rwx,g=rx,o="; }
  ];

  environment.persistence."/var/residues".users.pedrohlc.directories = [
    ".cache/nvidia"
  ];

  # Shadow can't be added to persistent
  users.users."melinapn".hashedPasswordFile = "/var/persistent/secrets/shadow/melinapn";

  # Proper output to gamescope
  programs.gamescope.args = [ "--prefer-vk-device 8086:8a60" ];

  # Appley key map
  services.udev.extraHwdb = ''
    evdev:input:b0011v0001*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_0001D=key_leftmeta
      KEYBOARD_KEY_000DB=key_leftalt
      KEYBOARD_KEY_00038=key_leftctrl
  '';

  # Sets the nvidia package globally, but does not enable it
  hardware.nvidia =
    let
      # Preferred NVIDIA Version
      nvidiaPackage =
        if config.boot.kernelPackages.nvidiaPackages.latest.version == "570.153.02" then
          nvidiaPatched
        else
          config.boot.kernelPackages.nvidiaPackages.latest;

      nvidiaPatched = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "575.57.08";
        sha256_64bit = "sha256-KqcB2sGAp7IKbleMzNkB3tjUTlfWBYDwj50o3R//xvI=";
        sha256_aarch64 = "sha256-VJ5z5PdAL2YnXuZltuOirl179XKWt0O4JNcT8gUgO98=";
        openSha256 = "sha256-DOJw73sjhQoy+5R0GHGnUddE6xaXb/z/Ihq3BKBf+lg=";
        settingsSha256 = "sha256-AIeeDXFEo9VEKCgXnY3QvrW5iWZeIVg4LBCeRtMs5Io=";
        persistencedSha256 = "sha256-Len7Va4HYp5r3wMpAhL4VsPu5S0JOshPFywbO7vYnGo=";

        patches = [ gpl_symbols_linux_615_patch ];
      };

      gpl_symbols_linux_615_patch = pkgs.fetchpatch {
        url = "https://github.com/CachyOS/kernel-patches/raw/914aea4298e3744beddad09f3d2773d71839b182/6.15/misc/nvidia/0003-Workaround-nv_vm_flags_-calling-GPL-only-code.patch";
        hash = "sha256-YOTAvONchPPSVDP9eJ9236pAPtxYK5nAePNtm2dlvb4=";
        stripLen = 1;
        extraPrefix = "kernel/";
      };
    in
    {
      package = nvidiaPackage;
      open = false;
    };

  # Creates a second boot entry with proprietary NVIDIA GPU (PRIME Offloading + Wayland)
  specialisation.nvidia-proprietary.configuration = { config, pkgs, ... }: # My user-named values.
    {
      system.nixos.tags = [ "nvidia-proprietary" ];

      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
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

      chaotic.mesa-git.enable = lib.mkForce false;

      home-manager.extraSpecialArgs.usingNouveau = false;
    };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "24.11"; # Did you read the comment?
}
