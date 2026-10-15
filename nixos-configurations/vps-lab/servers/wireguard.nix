{ pkgs, ssot, ... }: with ssot;
let
  eth0 = "enp0s3";

  multicastV4 = "224.0.0.251/32";
  multicastV6 = "ff02::fb/128";

  vpnClient = { wgKey, vpn, hostname, ... }:
    {
      publicKey = wgKey;
      allowedIPs = [
        "${vpn.v4}/32"
        "${vpn.v6}/128"
        multicastV4
        multicastV6
      ];
      name = hostname;
    };

  vpnClients =
    builtins.map vpnClient (builtins.filter (x: x.vpn.leaf != "1") (builtins.attrValues ssot.machines));
in
{
  networking = {
    nat = {
      enable = true;
      enableIPv6 = true;
      externalInterface = eth0;
      internalInterfaces = [ "wg0" ];
    };

    wireguard = {
      interfaces = {
        "wg0" = {
          ips = [ "${machines.lab.vpn.v4}/${vpn.mask.v4}" "${machines.lab.vpn.v6}/${vpn.mask.v6}" ];
          listenPort = vpn.port;
          privateKeyFile = "/var/persistent/secrets/wireguard-keys/private";
          peers = vpnClients ++ [
            {
              name = "mel";
              publicKey = "EBBn0i3SdqM9KUpYsl2vGs8oV3hmEy+cPkGNSep4RCQ=";
              allowedIPs = [
                "${vpn.prefix.v4}.102/32"
                "${vpn.prefix.v6}:102/128"
                multicastV4
                multicastV6
              ];
            }
            # christian
            {
              name = "christian";
              publicKey = "eQQHkO0cxZ3t94JlWSDzfHZgApU2ObdW4Uj2jQ8fPFw=";
              allowedIPs = [
                "${vpn.prefix.v4}.222/32"
                "${vpn.prefix.v6}:222/128"
                multicastV4
                multicastV6
              ];
            }
          ];
          postSetup = ''
            ip link set wg0 multicast on
            ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${vpn.prefix.v4}.0/24 -o ${eth0} -j MASQUERADE
            ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${vpn.prefix.v6}:0/64 -o ${eth0} -j MASQUERADE
          '';
          postShutdown = ''
            ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${vpn.prefix.v4}.0/24 -o ${eth0} -j MASQUERADE
            ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s ${vpn.prefix.v6}:0/24 -o ${eth0} -j MASQUERADE
          '';
        };
      };
    };
  };

  # ip forwarding (missing NAT sysctl)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };
}
