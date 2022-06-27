# The top lambda and it super set of parameters.
{ config, lib, pkgs, nix-gaming, ... }:

# NixOS-defined options
{
  # per-device UID
  users.users.pedrohlc.uid = 1001;
  users.users.melinapn.uid = 1000;

  # Network.
  networking = {
    hostId = "7116ddca";
    hostName = "desktop";
  };

  # DuckDNS
  services.ddclient = {
    enable = true;
    domains = [ "desk-pedrohlc.duckdns.org" ];
    protocol = "duckdns";
    server = "www.duckdns.org";
    username = "nouser";
    passwordFile = "home/pedrohlc/Projects/com.pedrohlc/duckdns.token";
    ipv6 = false; # Does not work for duckdns protocol
  };

  # Better voltage and temperature
  boot.extraModulePackages = with config.boot.kernelPackages; [ zenpower ];

  # Let's use AMD P-State
  boot.kernelParams = [
    "initcall_blacklist=acpi_cpufreq_init"
  ];
  # Services/Programs configurations
  services.minidlna.friendlyName = "desktop";

  # OpenCL
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];

  # This desktop is affected by this bug:
  #  - https://bugzilla.kernel.org/show_bug.cgi?id=216096 in kernel 5.18
  #  - Looks like you can't have two identical NVMes right now.
  # (lib.mkDefault because I also have a safer specialisation)
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages;
  boot.zfs.enableUnstable = lib.mkDefault false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "21.11"; # Did you read the comment?
}

