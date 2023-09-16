# The top lambda and it super set of parameters.
{ config, pkgs, lib, ssot, ... }: with ssot;

# NixOS-defined options
{
  # Network.
  networking = {
    hostId = "7116ddca";
    hostName = vpn.desktop.hostname;

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "${vpn.desktop.v4}/${vpn.mask.v4}" "${vpn.desktop.v6}/${vpn.mask.v6}" ];
      privateKeyFile = "/var/persistent/secrets/wireguard-keys/private";
    };

    wireguard.interfaces.wg1.privateKeyFile = "/var/persistent/secrets/wgcf-teams/private";
  };

  # UPS
  power.ups = {
    enable = true;
    ups.tsshara = {
      driver = "nutdrv_qx";
      description = "tsshara";
      port = "/dev/ttyACM0";
    };
  };

  # DuckDNS
  chaotic.duckdns = {
    enable = true;
    domain = web.desktop.addr;
    environmentFile = "/var/persistent/secrets/duckdns.env";
  };

  # Better voltage and temperature
  boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];
  boot.blacklistedKernelModules = [ "k10temp" ];

  boot.kernelParams = [
    # nvme1: controller is down; will reset: CSTS=0xffffffff, PCI_STATUS=0xffff
    #   Unable to change power state from D3cold to D0, device inaccessible
    # nvme1: Disabling device after reset failure: -19
    "nvme_core.default_ps_max_latency_us=0"
    "pcie_aspm=off"
    # Let's use AMD P-State
    "amd-pstate=guided"
  ];

  # OpenCL
  chaotic.mesa-git.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
    mesa_git.opencl
  ];
  environment.variables.RADV_VIDEO_DECODE = "1";

  # My mono-mic Focusrite
  environment.etc.pw-focusrite-mono-input = {
    source = pkgs.pw-focusrite-mono-input;
    target = "pipewire/pipewire.conf.d/99-focusrite-mono-input.conf";
  };

  # Up-to 192kHz in the Focusrite
  environment.etc.pw-96khz = {
    target = "pipewire/pipewire.conf.d/99-playback-96khz.conf";
    text = ''
      context.properties = {
        default.clock.rate = 96000
        default.clock.allowed-rates = [ 44100 48000 88200 96000 176400 192000 ]
      }
    '';
  };

  # Up-to 192kHz in the Focusrite (thanks to https://another.maple4ever.net/archives/2994/)
  # and virtualization MSRS
  boot.extraModprobeConfig = ''
    options snd_usb_audio vid=0x1235 pid=0x8211 device_setup=1 quirk_flags=0x1
    options kvm ignore_msrs=1
  '';


  # B550I AORUS PRO AX issue with suspension
  systemd.services.fix-b550i-acpi-wakeup = {
    description = "Disable misbehaving device from waking-up computer from sleep.";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo GPP0 > /proc/acpi/wakeup
    '';
  };

  # Gaming mouse stuff
  services.ratbagd.enable = true;

  # Limit resources used by nix-daemon.
  systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "3-23";

  # Extra packages
  environment.systemPackages = with pkgs; [
    devilutionx
    duckstation
    latencyflex-vulkan
    openrct2
    vcmi
    vkBasalt
    yuzu-early-access_git
    (cfwarp-add.override { gatewayIP = "192.168.18.1"; })
    virtiofsd # for libvirtd
  ];

  # One-button virtualization for some tests of mine
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };
  users.extraUsers.pedrohlc.extraGroups = [ "libvirtd" ];

  # Not important but persistent files
  environment.persistence = {
    "/var/persistent" = {
      users.pedrohlc.directories = [
        ".local/share/diasurgical"
        ".local/share/vcmi"
      ];
      files = [
        "/etc/nut/upsd.conf"
        "/etc/nut/upsd.users"
        "/etc/nut/upsmon.conf"
      ];
    };
    "/var/residues" = {
      users.pedrohlc.directories = [
        ".cache/vcmi"
        ".config/OpenRCT2"
        ".config/vcmi"
        ".config/VCMI Team"
      ];
      directories = [
        "/var/lib/nut"
        "/var/lib/libvirt"
      ];
    };
  };

  # Smooth-criminal bleeding-edge Mesa3D
  chaotic.mesa-git = {
    enable = true;
    fallbackSpecialisation = false;
  };

  # Add a second boot entry with HDR
  chaotic.hdr = {
    enable = true;
    specialisation.enable = false;
  };

  # Gamescope session is better for AAA gaming
  programs.steam.gamescopeSession.enable = true;

  # More Classics' gaming
  chaotic.steam.extraCompatPackages = with pkgs; [ luxtorpeda proton-ge-custom ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "22.05"; # Did you read the comment?
}

