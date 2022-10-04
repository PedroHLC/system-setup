{ pkgs, ... }:
let
  eth0 = "enp0s3";

  wgPrefixV4 = "10.100.0";
  wgPrefixV6 = "fda4:4413:3bb1:";
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
        wg0 = {
          ips = [ "${wgPrefixV4}.1/24" "${wgPrefixV6}:1/64" ];
          listenPort = 51820;
          privateKeyFile = "/home/pedrohlc/Projects/com.pedrohlc/wireguard-keys/private";
          peers = [
            # Desktop
            {
              publicKey = "cU6dpSqyloVRf6Jjb84TygJO94NOCy+LnMYv6/QAbBs=";
              allowedIPs = [
                "${wgPrefixV4}.2/32"
                "${wgPrefixV6}:2/128"
                # Multicast
                "224.0.0.251/32"
                "ff02::fb/128"
              ];
            }
            # Laptop
            {
              publicKey = "sS6SMVRPPvTGdjVBUScWkYqT8jjT8PIWy0kzMklwITM=";
              allowedIPs = [
                "${wgPrefixV4}.3/32"
                "${wgPrefixV6}:3/128"
                # Multicast
                "224.0.0.251/32"
                "ff02::fb/128"
              ];
            }
            # POCO X3
            {
              publicKey = "j6bZsZZoWfN4SaJuCxP2ndqWGc75A2JH3gxNwSbIDEM=";
              allowedIPs = [
                "${wgPrefixV4}.4/32"
                "${wgPrefixV6}:4/128"
                # Multicast
                "224.0.0.251/32"
                "ff02::fb/128"
              ];
            }
            # JurosComposto (atila)
            {
              publicKey = "tIQzW4+qfv2V8aCLwxJnWRnF+pjV3yRxTRuCPnA2CEA=";
              allowedIPs = [
                "${wgPrefixV4}.202/32"
                "${wgPrefixV6}:202/128"
                # Multicast
                "224.0.0.251/32"
                "ff02::fb/128"
              ];
            }
            # kojiro (atila)
            {
              publicKey = "kBVBMFXlj9m6TTy0nBeKBOyaqo5ulBUaPddFTTA2CFc=";
              allowedIPs = [
                "${wgPrefixV4}.203/32"
                "${wgPrefixV6}:203/128"
                # Multicast
                "224.0.0.251/32"
                "ff02::fb/128"
              ];
            }
            # kotaro (atila)
            {
              publicKey = "sJgsAYeBx0aE8es0Yfps0f7fBRpUvcxgyB19EM7wi1M=";
              allowedIPs = [
                "${wgPrefixV4}.204/32"
                "${wgPrefixV6}:204/128"
                # Multicast
                "224.0.0.251/32"
                "ff02::fb/128"
              ];
            }
            # celular de sabrina (atila)
            {
              publicKey = "VIDFaQvPJKkE6Ppc/PSjXt1TuzQMFhF5wL6qytKi5zk=";
              allowedIPs = [
                "${wgPrefixV4}.205/32"
                "${wgPrefixV6}:205/128"
                # Multicast
                "224.0.0.251/32"
                "ff02::fb/128"
              ];
            }

          ];
          postSetup = ''
                        ip link set wg0 multicast on
            	    ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -j ACCEPT
            	    ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s ${wgPrefixV4}.0/24 -o ${eth0} -j MASQUERADE
            	    ${pkgs.iptables}/bin/ip6tables -A FORWARD -i wg0 -j ACCEPT
            	    ${pkgs.iptables}/bin/ip6tables -t nat -A POSTROUTING -s ${wgPrefixV6}:0/64 -o ${eth0} -j MASQUERADE
          '';
          postShutdown = ''
            ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s ${wgPrefixV4}.0/24 -o ${eth0} -j MASQUERADE
            ${pkgs.iptables}/bin/ip6tables -D FORWARD -i wg0 -j ACCEPT
            ${pkgs.iptables}/bin/ip6tables -t nat -D POSTROUTING -s ${wgPrefixV6}:0/24 -o ${eth0} -j MASQUERADE
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
