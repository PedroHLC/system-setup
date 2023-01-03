{ ... }:
{
  networking = {
    wireguard.interfaces.wg1 = {
      ips = [ "2606:4700:110:839a:9b59:592b:2f69:4a14/128" "172.16.0.2/32" ];
      privateKeyFile = "/var/persistent/secrets/wgcf-teams/private";
      mtu = 1420;
      peers = [
        {
          publicKey = "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=";
          allowedIPs = [ "0.0.0.0/0" "::/0" ];
          endpoint = "engage.cloudflareclient.com:2408";
        }
      ];
      # I have access to all the network through allowedIPs
      # But I prefer to specify which routes to access
      allowedIPsAsRoutes = false;
      postSetup = ''
        ip route replace 172.16.0.2/31 dev wg1 table main
      '';
      postShutdown = ''
        ip route del 172.16.0.2/31 dev wg1
      '';
    };
    hosts."162.159.192.1" = [ "engage.cloudflareclient.com" ];
  };
}
