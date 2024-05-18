{ flakes, pkgs, ... }:
{
  systemd.services.ctr = {
    enable = true;
    description = "CTR-ModSDK Online Server";
    serviceConfig = {
      User = "pedrohlc";
      Group = "users";
      ExecStart = "${flakes.ctr.packages.${pkgs.system}.online-server.release.native32.gcc}/bin/ctr_srv -p 65001";
      Restart = "always";
      RestartSec = "8";
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
