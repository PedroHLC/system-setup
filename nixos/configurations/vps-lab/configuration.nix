# The top lambda and it super set of parameters.
{ config, ssot, lib, knownClients, ... }: with ssot;

# NixOS-defined options
{
  # OCI-related config
  oci.efi = true;

  # Network.
  networking = {
    hostId = "be2568e1";
    hostName = vpn.lab.hostname;
    useNetworkd = lib.mkForce false;
    resolvconf.extraConfig = ''
      name_servers="169.254.169.254 172.64.36.1 172.64.36.2"
    '';
  };

  # Let's Encrypt
  security.acme = {
    acceptTerms = true;
    defaults.email = contact.email;
    certs."${web.lab.addr}".extraDomainNames = [ web.zeta.addr web.dev.addr ];
  };

  # Changing the congestion algorithm to bbr in order to reduce packet loss at low throughput
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  # Sadly the internet is not a peaceful place
  networking.firewall = {
    enable = lib.mkOverride 99 true;
    allowedTCPPorts = [ 53 80 443 853 8448 ];
    allowedUDPPorts = [ 443 853 vpn.port 64001 8448 ];
    trustedInterfaces = [ "wg0" ];
    # ICMP traffic is blocked by default by OCI
    allowPing = true;
    # Keep UDP Plain DNS between family
    extraCommands = ''
      ${builtins.concatStringsSep "\n"
          (map (cidr: "ip${if lib.strings.hasInfix ":" cidr then "6" else ""}tables -A INPUT -p udp -s ${cidr} --dport 53 -j ACCEPT")
            knownClients.goodGuysCIDRs)
      }
      iptables -A INPUT -p udp --dport 53 -j REJECT
      ip6tables -A INPUT -p udp --dport 53 -j REJECT
    '';
  };

  # We can trim this one
  services.fstrim.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.05"; # Did you read the comment?
  home-manager.users.pedrohlc.home.stateVersion = "22.05";
}
