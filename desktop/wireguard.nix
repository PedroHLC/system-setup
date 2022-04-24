{ pkgs, ... }:
let
  iptables = "${pkgs.iptables}/bin/iptables";
  ip6tables = "${pkgs.iptables}/bin/ip6tables";
in
{
  networking = {
    nat = {
      enable = true;
      externalInterface = "eth0";
      internalInterfaces = [ "wg0" ];
    };

    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.100.0.1/24" "fda4:4413:3bb1::1/64" ];
          listenPort = 51820;
          privateKeyFile = "/home/pedrohlc/Projects/com.pedrohlc/wireguard-keys/private";
          peers = [
            {
              # Laptop
              publicKey = "sS6SMVRPPvTGdjVBUScWkYqT8jjT8PIWy0kzMklwITM=";
              allowedIPs = [
                "10.100.0.2/32"
		"fda4:4413:3bb1::2/128"
                # Multicast
                "224.0.0.251/32"
                "ff02::fb/128"
              ];
            }
          ];
          postSetup = ''
            ip link set wg0 multicast on

            ${iptables}  -A FORWARD -i %i -j ACCEPT
            ${iptables}  -A FORWARD -o %i -j ACCEPT
            ${iptables}  -t nat -A POSTROUTING -o eth0 -j MASQUERADE

            ${ip6tables} -A FORWARD -i %i -j ACCEPT
            ${ip6tables} -A FORWARD -o %i -j ACCEPT
            ${ip6tables} -t nat -A POSTROUTING -o eth0 -j MASQUERADE
          '';
          postShutdown = ''
            ${iptables}  -D FORWARD -i %i -j ACCEPT
            ${iptables}  -D FORWARD -o %i -j ACCEPT
            ${iptables}  -t nat -D POSTROUTING -o eth0 -j MASQUERADE

            ${ip6tables} -D FORWARD -i %i -j ACCEPT
            ${ip6tables} -D FORWARD -o %i -j ACCEPT
            ${ip6tables} -t nat -D POSTROUTING -o eth0 -j MASQUERADE
          '';
        };
      };
    };
  };

  # ip forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
}
