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

    # Plymouth stuff
    "i915.fastboot=1"
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
    hostName = machines.laptop.hostname;

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "${machines.laptop.vpn.v4}/${vpn.mask.v4}" "${machines.laptop.vpn.v6}/${vpn.mask.v6}" ];
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
      # "WLR_DRM_DEVICES" = "/dev/dri/by-path/pci-0000:00:02.0-card"; # BROKEN: https://gitlab.freedesktop.org/wlroots/wlroots/-/issues/1386
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
        inherit (config.boot.initrd) extraFirmwarePaths;
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

  # Emulates macbook keyboard mapping
  services.udev.extraHwdb = ''
    evdev:input:b0011v0001*
      ID_INPUT_KEY=1
      KEYBOARD_KEY_0001D=key_leftalt
      KEYBOARD_KEY_000DB=key_leftmeta
      KEYBOARD_KEY_00038=key_leftctrl
  '';

  # Loads GPU earlier in boot
  boot.initrd.availableKernelModules = [ "i915" ];

  # Sets the nvidia package globally, but does not enable it
  hardware.nvidia =
    let
      # Preferred NVIDIA Version
      nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.latest;
    in
    {
      package = nvidiaPackage;
      open = true;
      nvidiaSettings = false;
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
