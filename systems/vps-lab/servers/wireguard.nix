{ pkgs, ssot, ... }: with ssot;
let
  eth0 = "enp0s3";

  multicastV4 = "224.0.0.251/32";
  multicastV6 = "ff02::fb/128";
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
          ips = [ "${vpn.lab.v4}/${vpn.mask.v4}" "${vpn.lab.v6}/${vpn.mask.v6}" ];
          listenPort = vpn.port;
          privateKeyFile = "/home/pedrohlc/Projects/com.pedrohlc/wireguard-keys/private";
          peers = [
            # Desktop
            {
              publicKey = "cU6dpSqyloVRf6Jjb84TygJO94NOCy+LnMYv6/QAbBs=";
              allowedIPs = [
                "${vpn.desktop.v4}/32"
                "${vpn.desktop.v6}/128"
                multicastV4
                multicastV6
              ];
            }
            # Laptop
            {
              publicKey = "sS6SMVRPPvTGdjVBUScWkYqT8jjT8PIWy0kzMklwITM=";
              allowedIPs = [
                "${vpn.laptop.v4}/32"
                "${vpn.laptop.v6}/128"
                multicastV4
                multicastV6
              ];
            }
            # POCO X3
            {
              publicKey = "j6bZsZZoWfN4SaJuCxP2ndqWGc75A2JH3gxNwSbIDEM=";
              allowedIPs = [
                "${vpn.prefix.v4}.4/32"
                "${vpn.prefix.v6}:4/128"
                multicastV4
                multicastV6
              ];
            }
            # JurosComposto (atila)
            {
              publicKey = "tIQzW4+qfv2V8aCLwxJnWRnF+pjV3yRxTRuCPnA2CEA=";
              allowedIPs = [
                "${vpn.prefix.v4}.202/32"
                "${vpn.prefix.v6}:202/128"
                multicastV4
                multicastV6
              ];
            }
            # kojiro (atila)
            {
              publicKey = "kBVBMFXlj9m6TTy0nBeKBOyaqo5ulBUaPddFTTA2CFc=";
              allowedIPs = [
                "${vpn.prefix.v4}.203/32"
                "${vpn.prefix.v6}:203/128"
                multicastV4
                multicastV6
              ];
            }
            # kotaro (atila)
            {
              publicKey = "sJgsAYeBx0aE8es0Yfps0f7fBRpUvcxgyB19EM7wi1M=";
              allowedIPs = [
                "${vpn.prefix.v4}.204/32"
                "${vpn.prefix.v6}:204/128"
                multicastV4
                multicastV6
              ];
            }
            # notebook de sabrina (atila)
            {
              publicKey = "4BtCrkUKDU5MAgUk3PFtnvxvT8KUNztaexej0eKjuks=";
              allowedIPs = [
                "${vpn.prefix.v4}.205/32"
                "${vpn.prefix.v6}:205/128"
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
