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

    users.first = {
      passwordFile = "/var/persistent/secrets/ups.psw";
      upsmon = "master";
    };

    upsmon.monitor.tsshara = {
      user = "first";
    };
  };

  # DuckDNS
  chaotic.duckdns = {
    enable = true;
    domain = web.desktop.addr;
    environmentFile = "/var/persistent/secrets/duckdns.env";
  };

  # Better voltage, temperature, and a module to save me in case everything catches fire
  boot.extraModulePackages = with config.boot.kernelPackages; [
    zenpower
    (pkgs.callPackage ../../shared/drvs/ksysrqd.nix { inherit kernel; })
  ];
  boot.blacklistedKernelModules = [ "k10temp" ];

  # The service to start ksysrqd with my secret
  systemd.services.ksysrqd = {
    description = "Load ksysrqd module at boot";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "ksysrqd-ins" ''
        ${pkgs.kmod}/bin/modprobe ksysrqd password=$(cat /var/persistent/secrets/ksysrqd.psw)
      '';
      RemainAfterExit = true;
    };

    wantedBy = [ "multi-user.target" ];
  };

  boot.kernelParams = [
    # nvme1: controller is down; will reset: CSTS=0xffffffff, PCI_STATUS=0xffff
    #   Unable to change power state from D3cold to D0, device inaccessible
    # nvme1: Disabling device after reset failure: -19
    # "pcie_aspm=off"  "nvme_core.default_ps_max_latency_us=0"

    # Let's use AMD P-State
    "amd-pstate=guided"
  ];

  # OpenCL
  chaotic.mesa-git.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    rocmPackages.clr
    mesa_git.opencl
  ];
  environment.variables.RADV_PERFTEST = "sam,video_decode";

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
  systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "2-23";

  # Extra packages
  environment.systemPackages = with pkgs; [
    devilutionx
    duckstation
    latencyflex-vulkan
    openmohaa_git
    openrct2
    vcmi
    vkbasalt
    vkshade_git
    yuzu-early-access_git
    (cfwarp-add.override { substitutions = { "192.168.0.1" = "192.168.18.1"; }; })
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

  # Allows building v4 packages
  nix.settings.system-features = [ "big-parallel" "gccarch-x86-64-v3" ];

  # Allows HDR gaming (AMD-GPU only).
  chaotic.hdr = {
    enable = true;
    specialisation.enable = false;
  };

  # More Classics' gaming
  chaotic.steam.extraCompatPackages = with pkgs; [ luxtorpeda proton-ge-custom ];

  # Experimentation
  specialisation.sched-ext.configuration = {
    system.nixos.tags = [ "sched-ext" ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos-sched-ext;
    environment.systemPackages = [ pkgs.scx ];
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

