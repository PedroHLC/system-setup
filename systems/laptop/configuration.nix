# The top lambda and it super set of parameters.
{ config, lib, pkgs, ssot, ... }: with ssot;

# NixOS-defined options
{
  # Force full IOMMU and enable GSP usage
  boot.kernelParams = [ "intel_iommu=on" "nouveau.config=NvGspRm=1" "nouveau.debug=\"GSP=debug\"" ];

  # More stuff have GSP
  boot.initrd.kernelModules = [ "nouveau" ];

  # Add stuff to pkgs.*
  nixpkgs.overlays = [
    (final: prev: {
      # Bring GSP and related GPU stuff, but without any other GPU
      makeModulesClosure = args: (prev.makeModulesClosure args).overrideAttrs (prevAttrs: {
        builder = final.runCommand "modules-closure.sh" { } ''
          cat ${prevAttrs.builder} > $out
          chmod +x $out
          echo 'rm -rf "$out/lib/firmware/nvidia"' >> $out
          echo 'mkdir -p "$out/lib/firmware/nvidia"' >> $out
          echo 'cp --no-preserve=mode -r "$firmware/lib/firmware/nvidia/ga10"{2,7} "$out/lib/firmware/nvidia/"' >> $out
          echo 'pushd "$out/lib/firmware/nvidia/ga107"' >> $out
          echo 'rm -rf gsp.xz' >> $out
          echo 'ln -s ../ga102/gsp ./gsp' >> $out
          echo 'popd' >> $out
        '';
      });

      # Allow steam to find nvidia-offload script
      steam = prev.steam.override {
        extraPkgs = _: [ final.nvidia-offload ];
      };

      # NVIDIA Offloading (ajusted to work on Wayland and XWayland).
      nvidia-offload = final.callPackage ../../shared/scripts { scriptName = "nvidia-offload"; };

      # Latest firmware
      linux-firmware = prev.linux-firmware.overrideAttrs (_: {
        src = final.fetchzip {
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/snapshot/linux-firmware-b3132c18d0be905d352dddf554230b14fc7eab5c.tar.gz";
          hash = "sha256-Mg9BLB3x19wwaIIsydO/jy0hYEUfiZC1xPdRsN7p4WU=";
        };
        outputHash = "sha256-xbE/Z0dl2bXMmgwphenfNS9BC/7lMeFoPcTLsk2NCbY=";
      });
    })
  ];

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
      "VK_ICD_FILENAMES" = "/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json:/run/opengl-driver-32/share/vulkan/icd.d/intel_icd.i686.json";
      "LIBVA_DRIVER_NAME" = "iHD";
    };
  };

  # Intel VAAPI (NVIDIA enable its own)
  hardware.opengl.extraPackages = with pkgs; [
    intel-media-driver
  ];

  # Useful services for power-saving
  services.auto-cpufreq.enable = true;
  services.power-profiles-daemon.enable = false; # replaced by tlp
  services.tlp.enable = true;
  services.upower.enable = true;

  # Limit resources used by nix-daemon.
  systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "3-15";

  # Melina may also use this machine
  users.users.melinapn = {
    uid = 1002;
    isNormalUser = true;
    extraGroups = [ "users" "audio" "video" "input" "networkmanager" ];
  };

  # Plasma for Melina
  services.xserver.desktopManager.plasma5.enable = true;

  # Autologin (with Melina).
  services.getty.loginOptions =
    let
      programScript = pkgs.callPackage ../../shared/drvs/login-program.nix {
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

  # For me to know what to use inside Home-Manager
  home-manager.extraSpecialArgs.usingNouveau = true;

  # Creates a second boot entry with proprietary NVIDIA GPU (PRIME Offloading + Wayland)
  specialisation.nvidia-proprietary.configuration = { config, pkgs, ... }: # My user-named values.
    let
      # Preferred NVIDIA Version.
      nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.latest;

    in
    {
      system.nixos.tags = [ "nvidia-proprietary" ];

      services.xserver.videoDrivers = [ "nvidia" ];
      hardware.nvidia = {
        package = nvidiaPackage;
        #open = true; # I was having issues with NVRAM

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
  system.stateVersion = "23.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "23.11"; # Did you read the comment?
}

