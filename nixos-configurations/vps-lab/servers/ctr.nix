{ flakes, pkgs, ... }:

let
  pkg = flakes.ctr.packages.${pkgs.stdenv.hostPlatform.system}.online-server.release.native.gcc;
in
{
  systemd.services.ctr = {
    enable = true;
    description = "CTR-ModSDK Online Server";
    serviceConfig = {
      User = "pedrohlc";
      Group = "users";
      ExecStart = "${pkg}/bin/ctr_srv -p 64001";
      Restart = "always";
      RestartSec = "8";
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
  };
}
