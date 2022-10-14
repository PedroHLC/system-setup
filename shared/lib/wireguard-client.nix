{ ssot, ... }: with ssot;
{
  networking = {
    wireguard.interfaces.wg0 =
      {
        # In the configuration add `ips` and `privateKeyFile`.
        peers = [
          {
            publicKey = "kjVAAeIGsN0r3StYDQ2vnYg6MbclMrPALdm07qZtRCE=";
            allowedIPs = [
              "0.0.0.0/0"
              "::/0"
            ];
            endpoint = "${web.lab.addr}:${toString vpn.port}";
            persistentKeepalive = 25;
          }
        ];
        # I have access to all the network through allowedIPs
        # But by default, I only want routes to the VPN clients and multicast
        allowedIPsAsRoutes = false;
        postSetup = ''
          ip link set wg0 multicast on
          ip route replace "${vpn.subnet.v4}" dev wg0 table main
          ip route replace "${vpn.subnet.v6}" dev wg0 table main
        '';
        postShutdown = ''
          ip route del "${vpn.subnet.v4}" dev wg0
          ip route del "${vpn.subnet.v6}" dev wg0
        '';
      };
  };
}
