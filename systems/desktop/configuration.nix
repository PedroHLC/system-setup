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


  # DuckDNS
  services.ddclient = {
    enable = false; # currently broken
    domains = [ web.desktop.addr ];
    protocol = "duckdns";
    server = "www.duckdns.org";
    username = "nouser";
    passwordFile = "/var/persistent/secrets/duckdns.token";
    ipv6 = false; # Does not work for duckdns protocol
  };

  # Better voltage and temperature
  boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];

  # Let's use AMD P-State
  boot.kernelParams = [
    #"initcall_blacklist=acpi_cpufreq_init"
    "amd_pstate.shared_mem=1"
    # Fix "controller is down" (probably)
    "nvme_core.default_ps_max_latency_us=0"
  ];
  boot.kernelModules = [ "amd_pstate" ];

  # OpenCL
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
  environment.variables.RADV_VIDEO_DECODE = "1";

  # My mono-mic Focusrite
  environment.etc.pw-focusrite-mono-input = {
    source = pkgs.pw-focusrite-mono-input;
    target = "pipewire/pipewire.conf.d/focusrite-mono-input.conf";
  };

  # B550I AORUS PRO AX issue with suspension
  systemd.services.fix-b550i-acpi-wakeup = {
    description = "Disable misbehaving device from waking-up computer from sleep.";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      echo GPP0 > /proc/acpi/wakeup
    '';
  };

  # Limit resources used by nix-daemon.
  systemd.services.nix-daemon.serviceConfig.AllowedCPUs = "3-23";

  # Extra packages
  environment.systemPackages = with pkgs; [
    vkBasalt
  ];

  # One-button virtualization for some tests of mine
  virtualisation.libvirtd.enable = true;
  users.extraUsers.pedrohlc.extraGroups = [ "libvirtd" ];
  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1
  '';

  # GameScope session
  programs.gamescope.enable = true;
  programs.steam.gamescopeSession.enable = true;

  # Creates a second boot entry with HDR
  specialisation.hdr.configuration = {
    system.nixos.tags = [ "hdr" ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_testing_hdr;
    environment.variables.ENABLE_GAMESCOPE_WSI = "1";
    programs.gamescope.args = lib.mkForce [ "--rt" "--prefer-vk-device 8086:9bc4" "--hdr-enabled" ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "22.05"; # Did you read the comment?
}

