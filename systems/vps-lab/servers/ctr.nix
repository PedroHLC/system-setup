{ flakes, pkgs, ... }:

let
  ctrService = room: {
    enable = true;
    description = "CTR-ModSDK Online Server";
    serviceConfig = {
      User = "pedrohlc";
      Group = "users";
      ExecStart = "${flakes.ctr.packages.${pkgs.system}.online-server.release.native32.gcc}/bin/ctr_srv -p 6500${room}";
      Restart = "always";
      RestartSec = "8";
      StandardOutput = "syslog";
      StandardError = "syslog";
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
in
{
  systemd.services = {
    ctr1 = ctrService "1";
    ctr2 = ctrService "2";
    ctr3 = ctrService "3";
    ctr4 = ctrService "4";
  };
}
