# The top lambda and it super set of parameters.
{ config, lib, pkgs, ... }:

# NixOS-defined options
{
  # OCI-related config
  oci.efi = true;

  # Network.
  networking = {
    hostId = "be2568e1";
    hostName = "vps-lab";
  };

  # Let's Encrypt
  security.acme = {
    acceptTerms = true;
    defaults.email = "root@pedrohlc.com";
    certs."lab.pedrohlc.com".extraDomainNames = [ "zeta.pedrohlc.com" ];
  };

  # Changing the congestion algorithm to bbr in order to reduce packet loss at low throughput
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "22.05";
}
