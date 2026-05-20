# The top lambda and it super set of parameters.
{ config, pkgs, lib, ssot, ... }: with ssot;

# NixOS-defined options
{
  # Network.
  networking = {
    hostId = "7116ddca";
    hostName = machines.desktop.hostname;

    # Wireguard Client
    wireguard.interfaces.wg0 = {
      ips = [ "${machines.desktop.vpn.v4}/${vpn.mask.v4}" "${machines.desktop.vpn.v6}/${vpn.mask.v6}" ];
      privateKeyFile = "/var/persistent/secrets/wireguard-keys/private";
    };

    wireguard.interfaces.wg1.privateKeyFile = "/var/persistent/secrets/wgcf-teams/private";
  };

  # UPS monitoring
  power.ups = {
    enable = false;
    ups.sms-gamer = {
      driver = "sms_ser";
      description = "sms-gamer";
      port = "/dev/ttyUSB0";
    };

    users.first = {
      passwordFile = "/var/persistent/secrets/ups.psw";
      upsmon = "primary";
    };

    upsmon.monitor.sms-gamer = {
      user = "first";
    };
  };

  # A module to save me in case everything catches fire
  boot.extraModulePackages = with config.boot.kernelPackages; [
    (callPackage ../../packages/ksysrqd.nix { })
  ];

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

  # Up-to 192kHz in the Focusrite
  services.pipewire.extraConfig.pipewire."99-playback-96khz" = {
    "context.properties" = {
      "default.clock.rate" = 96000;
      "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];
    };
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
    (cfwarp-add.override { substitutions = { "192.168.0.1" = "192.168.18.1"; }; })
    i2pd
    nixos-next-shot
    uxplay
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
        ".config/OpenRCT2"
        ".local/share/diasurgical"
        ".local/share/vcmi"
      ];
    };
    "/var/residues" = {
      users.pedrohlc.directories = [
        ".cache/vcmi"
        ".config/vcmi"
        ".config/VCMI Team"
      ];
      directories = [
        "/var/lib/nut"
        "/var/lib/libvirt"
      ];
    };
  };

  # Allows streaming with KMS
  security.wrappers.sunshine = {
    source = "${pkgs.sunshine}/bin/sunshine";
    capabilities = "cap_sys_admin+pie";
    owner = "root";
    group = "root";
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
